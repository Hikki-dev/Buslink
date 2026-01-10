const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// Collections
const ROUTE_COLLECTION = "routes";
const SCHEDULE_COLLECTION = "schedules";
const TRIP_COLLECTION = "trips";

async function generateTrips() {
  console.log("🚀 STARTING TRIP GENERATION (Next 30 Days)");

  // 1. Fetch All Schedules, Routes, and Users (for Conductor lookup if needed)
  const schedulesSnap = await db.collection(SCHEDULE_COLLECTION).get();
  const routesSnap = await db.collection(ROUTE_COLLECTION).get();

  if (schedulesSnap.empty) {
    console.log("❌ No schedules found! Run migrate.js first.");
    return;
  }

  // Map Routes for easy lookup
  const routeMap = {};
  routesSnap.docs.forEach((doc) => {
    routeMap[doc.id] = doc.data();
  });

  let createdCount = 0;
  let skippedCount = 0;
  const batchSize = 400; // Firestore Batch Limit is 500
  let batch = db.batch();
  let batchCount = 0;

  const today = new Date();
  today.setHours(0, 0, 0, 0); // Start of today

  for (const doc of schedulesSnap.docs) {
    const schedule = doc.data();
    const scheduleId = doc.id;
    const route = routeMap[schedule.routeId];

    if (!route) {
      console.log(
        `⚠️  Schedule ${scheduleId} has missing route ${schedule.routeId}`
      );
      continue;
    }

    // Parse Departure Time (HH:mm)
    const [depHour, depMin] = schedule.departureTime.split(":").map(Number);

    // Generate for next 30 days
    for (let i = 0; i < 30; i++) {
      const targetDate = new Date(today);
      targetDate.setDate(today.getDate() + i);

      // Check Recurrence (1=Mon, 7=Sun) in JS 0=Sun, 1=Mon...
      // Firestore Data: 1=Mon, 2=Tue... 7=Sun
      // JS getDay(): 0=Sun, 1=Mon... 6=Sat
      // Conversion: JS 0 -> 7, others match
      let jsDay = targetDate.getDay();
      let firestoreDay = jsDay === 0 ? 7 : jsDay;

      if (!schedule.recurrenceDays.includes(firestoreDay)) {
        continue;
      }

      // Construct Start/End of Day for Duplicate Check (Optimized: we trust the script is running fresh or we overwrite)
      // Actually, to be safe, let's just make a deterministic ID based on Schedule + Date
      // ID Format: sch_{scheduleId}_{YYYYMMDD}
      const yyyymmdd = targetDate.toISOString().split("T")[0].replace(/-/g, "");
      const tripId = `trip_${scheduleId}_${yyyymmdd}`;

      // Calculate Times
      const departureDateTime = new Date(targetDate);
      departureDateTime.setHours(depHour, depMin, 0, 0);

      const arrivalDateTime = new Date(departureDateTime);
      arrivalDateTime.setMinutes(
        arrivalDateTime.getMinutes() + (route.estimatedDurationMins || 120)
      ); // Default 2h if missing

      const tripData = {
        id: tripId,
        scheduleId: scheduleId,
        date: admin.firestore.Timestamp.fromDate(targetDate),
        originCity: route.originCity,
        destinationCity: route.destinationCity,
        departureDateTime:
          admin.firestore.Timestamp.fromDate(departureDateTime),
        arrivalDateTime: admin.firestore.Timestamp.fromDate(arrivalDateTime),
        price: Number(schedule.basePrice),
        status: "Scheduled",
        totalSeats: Number(schedule.totalSeats),
        delayMinutes: 0,
        bookedSeats: [],
        bookedSeatNumbers: [], // Dual field for compatibility
        conductorId: schedule.conductorId || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const tripRef = db.collection(TRIP_COLLECTION).doc(tripId);
      batch.set(tripRef, tripData, { merge: true }); // Merge ensures we don't wipe bookings if re-run

      batchCount++;
      createdCount++;

      // Commit Batch if full
      if (batchCount >= batchSize) {
        await batch.commit();
        console.log(`   💾 Committed batch of ${batchCount} trips...`);
        batch = db.batch();
        batchCount = 0;
      }
    }
    console.log(
      `   ✨ Processed Schedule ${scheduleId} (${route.originCity} -> ${route.destinationCity})`
    );
  }

  if (batchCount > 0) {
    await batch.commit();
    console.log(`   💾 Committed final batch of ${batchCount} trips...`);
  }

  console.log("------------------------------------------------");
  console.log(`🏁 TRIP GENERATION COMPLETE`);
  console.log(`   Created/Updated: ${createdCount} Trips`);
  console.log("------------------------------------------------");
}

generateTrips().catch(console.error);
