const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Collections
const ROUTE_COLLECTION = "routes";
const SCHEDULE_COLLECTION = "schedules";

async function migrateRoutesToSchedules() {
  console.log("🚀 STARTING MIGRATION: Routes -> Schedules (Node.js)");

  const routesSnap = await db.collection(ROUTE_COLLECTION).get();

  if (routesSnap.empty) {
    console.log("No routes found.");
    return;
  }

  console.log(`Found ${routesSnap.size} routes to check.`);

  let migratedCount = 0;
  let skippedCount = 0;

  const batchSize = 100; // Process in chunks if needed, but for now linear is fine for simplicity or small dataset

  for (const doc of routesSnap.docs) {
    const data = doc.data();
    const routeId = doc.id;

    // Check if it looks like a legacy route (has price/busNumber)
    // NOTE: We relaxed this check to force a 'Deep Clean' on already migrated routes too
    // if (!data.price && !data.busNumber) {
    //   console.log(`⏭️  Skipped Route ${routeId} (Already migrated or clean)`);
    //   skippedCount++;
    //   continue;
    // }

    console.log(
      `🔄 Migrating Route: ${routeId} (${data.originCity || data.fromCity} -> ${
        data.destinationCity || data.toCity
      })`
    );

    // 1. Prepare Schedule Data
    const scheduleId = db.collection(SCHEDULE_COLLECTION).doc().id;
    const depHour = data.departureHour ?? 8;
    const depMin = data.departureMinute ?? 0;
    const depTime = `${depHour}:${depMin.toString().padStart(2, "0")}`;

    const scheduleData = {
      id: scheduleId,
      routeId: routeId,
      busNumber: data.busNumber ?? "Unknown",
      operatorName: data.operatorName ?? "Buslink",
      busType: data.busType ?? "Standard",
      amenities: data.features || [],
      recurrenceDays: data.recurrenceDays || [1, 2, 3, 4, 5, 6, 7],
      departureTime: depTime,
      basePrice: Number(data.price) || 0,
      totalSeats: 40,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // 2. Perform Writes (Create Schedule + Update Route)
    // We'll do this in a Batch to ensure atomicity per route
    const batch = db.batch();

    const scheduleRef = db.collection(SCHEDULE_COLLECTION).doc(scheduleId);
    batch.set(scheduleRef, scheduleData);

    const routeRef = db.collection(ROUTE_COLLECTION).doc(routeId);

    // Determine strict Origin/Destination
    const origin = data.originCity || data.fromCity || "Unknown";
    const dest = data.destinationCity || data.toCity || "Unknown";

    batch.update(routeRef, {
      // 1. Remove Legacy / Trip-Specific Fields
      price: admin.firestore.FieldValue.delete(),
      busNumber: admin.firestore.FieldValue.delete(),
      operatorName: admin.firestore.FieldValue.delete(),
      busType: admin.firestore.FieldValue.delete(),
      features: admin.firestore.FieldValue.delete(),
      recurrenceDays: admin.firestore.FieldValue.delete(),
      departureHour: admin.firestore.FieldValue.delete(),
      departureMinute: admin.firestore.FieldValue.delete(),
      arrivalHour: admin.firestore.FieldValue.delete(),
      arrivalMinute: admin.firestore.FieldValue.delete(),
      platformNumber: admin.firestore.FieldValue.delete(),

      // Remove Trip Pollution (found in user screenshots)
      bookedSeats: admin.firestore.FieldValue.delete(),
      delayMinutes: admin.firestore.FieldValue.delete(),
      status: admin.firestore.FieldValue.delete(),
      arrivalTime: admin.firestore.FieldValue.delete(),
      departureTime: admin.firestore.FieldValue.delete(),
      isGenerated: admin.firestore.FieldValue.delete(),

      // Remove Old Names (we are migrating them)
      fromCity: admin.firestore.FieldValue.delete(),
      toCity: admin.firestore.FieldValue.delete(),

      // 2. Set New Schema Fields
      originCity: origin,
      destinationCity: dest,
      distanceKm: data.distanceKm || 0.0,
      estimatedDurationMins: data.estimatedDurationMins || 0,
      isActive: true,
      lastMigratedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    console.log(
      `   ✅ Created Schedule: ${scheduleId} | Price: ${scheduleData.basePrice}`
    );
    console.log(`   ✨ Cleaned Route ${routeId}`);

    migratedCount++;
  }

  console.log("------------------------------------------------");
  console.log(`🏁 MIGRATION COMPLETE`);
  console.log(`   Migrated: ${migratedCount}`);
  console.log(`   Skipped:  ${skippedCount}`);
  console.log("------------------------------------------------");
}

migrateRoutesToSchedules().catch(console.error);
