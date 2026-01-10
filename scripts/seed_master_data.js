const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// --- DATA DEFINITIONS ---

const TIMETABLE = [
  "05:00",
  "06:00",
  "07:00",
  "08:00",
  "10:00",
  "12:00",
  "14:00",
  "16:00",
  "21:00",
  "22:30",
];

// Helper to parse duration "3h 15m" -> minutes
function parseDuration(str) {
  const parts = str.match(/(\d+)h\s*(\d+)m/);
  if (!parts) return 120; // fallback
  return parseInt(parts[1]) * 60 + parseInt(parts[2]);
}

const MASTER_ROUTES = [
  {
    id: 1,
    origin: "Colombo",
    dest: "Kandy",
    variants: [
      { via: "Gampaha", duration: "3h 15m", price: 750, code: "GAM" },
      { via: "Kurunegala", duration: "3h 45m", price: 780, code: "KUR" },
    ],
  },
  {
    id: 2,
    origin: "Kandy",
    dest: "Colombo",
    variants: [
      { via: "Gampaha", duration: "3h 15m", price: 750, code: "GAM" },
      { via: "Kurunegala", duration: "3h 45m", price: 780, code: "KUR" },
    ],
  },
  {
    id: 3,
    origin: "Colombo",
    dest: "Galle",
    variants: [
      { via: "Kalutara", duration: "2h 20m", price: 650, code: "KAL" },
      { via: "Bentota", duration: "2h 30m", price: 670, code: "BEN" },
    ],
  },
  {
    id: 4,
    origin: "Galle",
    dest: "Colombo",
    variants: [
      { via: "Kalutara", duration: "2h 20m", price: 650, code: "KAL" },
      { via: "Bentota", duration: "2h 30m", price: 670, code: "BEN" },
    ],
  },
  {
    id: 5,
    origin: "Colombo",
    dest: "Jaffna",
    variants: [
      { via: "Vavuniya", duration: "7h 45m", price: 1650, code: "VAV" },
      { via: "Anuradhapura", duration: "8h 15m", price: 1700, code: "ANU" },
    ],
  },
  {
    id: 6,
    origin: "Jaffna",
    dest: "Colombo",
    variants: [
      { via: "Vavuniya", duration: "7h 45m", price: 1650, code: "VAV" },
      { via: "Anuradhapura", duration: "8h 15m", price: 1700, code: "ANU" },
    ],
  },
  {
    id: 7,
    origin: "Colombo",
    dest: "Trincomalee",
    variants: [
      { via: "Dambulla", duration: "6h 00m", price: 1350, code: "DAM" },
      { via: "Habarana", duration: "6h 15m", price: 1380, code: "HAB" },
    ],
  },
  {
    id: 8,
    origin: "Trincomalee",
    dest: "Colombo",
    variants: [
      { via: "Dambulla", duration: "6h 00m", price: 1350, code: "DAM" },
      { via: "Habarana", duration: "6h 15m", price: 1380, code: "HAB" },
    ],
  },
  {
    id: 9,
    origin: "Kandy",
    dest: "Galle",
    variants: [
      { via: "Matara", duration: "6h 30m", price: 1150, code: "MAT" },
      { via: "Colombo", duration: "7h 00m", price: 1100, code: "CMB" },
    ],
  },
  {
    id: 10,
    origin: "Galle",
    dest: "Kandy",
    variants: [
      { via: "Matara", duration: "6h 30m", price: 1150, code: "MAT" },
      { via: "Colombo", duration: "7h 00m", price: 1100, code: "CMB" },
    ],
  },
  {
    id: 11,
    origin: "Kandy",
    dest: "Jaffna",
    variants: [
      { via: "Dambulla", duration: "6h 30m", price: 1450, code: "DAM" },
      { via: "Anuradhapura", duration: "7h 00m", price: 1480, code: "ANU" },
    ],
  },
  {
    id: 12,
    origin: "Jaffna",
    dest: "Kandy",
    variants: [
      { via: "Dambulla", duration: "6h 30m", price: 1450, code: "DAM" },
      { via: "Anuradhapura", duration: "7h 00m", price: 1480, code: "ANU" },
    ],
  },
  {
    id: 13,
    origin: "Kandy",
    dest: "Trincomalee",
    variants: [
      { via: "Dambulla", duration: "4h 30m", price: 850, code: "DAM" },
      { via: "Habarana", duration: "4h 45m", price: 880, code: "HAB" },
    ],
  },
  {
    id: 14,
    origin: "Trincomalee",
    dest: "Kandy",
    variants: [
      { via: "Dambulla", duration: "4h 30m", price: 850, code: "DAM" },
      { via: "Habarana", duration: "4h 45m", price: 880, code: "HAB" },
    ],
  },
  {
    id: 15,
    origin: "Galle",
    dest: "Jaffna",
    variants: [
      { via: "Colombo", duration: "10h 00m", price: 1900, code: "CMB" },
      { via: "Anuradhapura", duration: "10h 30m", price: 1950, code: "ANU" }, // Actually usually via Colombo AND Anu, but following prompt
    ],
  },
  {
    id: 16,
    origin: "Jaffna",
    dest: "Galle",
    variants: [
      { via: "Colombo", duration: "10h 00m", price: 1900, code: "CMB" },
      { via: "Anuradhapura", duration: "10h 30m", price: 1950, code: "ANU" },
    ],
  },
  {
    id: 17,
    origin: "Galle",
    dest: "Trincomalee",
    variants: [
      { via: "Colombo", duration: "8h 30m", price: 1600, code: "CMB" },
      { via: "Kandy", duration: "9h 00m", price: 1650, code: "KDY" },
    ],
  },
  {
    id: 18,
    origin: "Trincomalee",
    dest: "Galle",
    variants: [
      { via: "Colombo", duration: "8h 30m", price: 1600, code: "CMB" },
      { via: "Kandy", duration: "9h 00m", price: 1650, code: "KDY" },
    ],
  },
  {
    id: 19,
    origin: "Jaffna",
    dest: "Trincomalee",
    variants: [
      { via: "Vavuniya", duration: "5h 00m", price: 950, code: "VAV" },
      { via: "Anuradhapura", duration: "5h 30m", price: 980, code: "ANU" },
    ],
  },
  {
    id: 20,
    origin: "Trincomalee",
    dest: "Jaffna",
    variants: [
      { via: "Vavuniya", duration: "5h 00m", price: 950, code: "VAV" },
      { via: "Anuradhapura", duration: "5h 30m", price: 980, code: "ANU" },
    ],
  },
];

// City Code Lookup for Trip Naming (CMB, KDY, etc.)
function getCityCode(city) {
  const map = {
    Colombo: "CMB",
    Kandy: "KDY",
    Galle: "GAL",
    Jaffna: "JFN",
    Trincomalee: "TRI",
  };
  return map[city] || city.substring(0, 3).toUpperCase();
}

async function wipeCollection(collectionName) {
  const snap = await db.collection(collectionName).limit(500).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`   Deleted batch from ${collectionName}`);
  await wipeCollection(collectionName); // recurse
}

async function seedMasterData() {
  console.log("🚀 STARTING MASTER DATA SEED (The 'Clean Slate')");

  // 1. Wipe Existing Data
  console.log("🗑️  Wiping existing Routes, Schedules, Trips...");
  await wipeCollection("routes");
  await wipeCollection("schedules");
  await wipeCollection("trips");
  console.log("   ✅ Cleaned.");

  // 2. Process Data
  const batchSize = 400;
  let batch = db.batch();
  let opCount = 0;

  let totalRoutes = 0;
  let totalSchedules = 0;
  let totalTrips = 0;

  // For Trip Generation
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const DAYS_TO_GENERATE = 30; // Generate 30 days of trips

  for (const r of MASTER_ROUTES) {
    // Create Route Documents (One per Variant to ensure unique 'Via' routing search?)
    // Domain model: Route = Origin+Dest.
    // BUT the prompt treats them ("Via Gampaha") as distinct list items with distinct durations.
    // If I merge them into one Route with "Via: Gampaha, Kurunegala", it matches schema, but search might need care.
    // To fit the "Exact Stuff" request: I will create ONE Route document for Origin-Dest pair,
    // but the Schedules will distinctively carry the 'Via' info.

    // Actually, distinct durations means distinct underlying routes.
    // Let's create unique IDs for them or just 1 Route doc?
    // If I make 1 Route doc, 'estimatedDurationMins' becomes ambiguous.
    // DECISION: Create 1 Route Document per Route Definition in the list (so 2 per pair if 2 vias).
    // This allows unique distance/duration per Via.

    for (const variant of r.variants) {
      const routeId = `route_${getCityCode(r.origin)}_${getCityCode(r.dest)}_${
        variant.code
      }`;
      const durationMins = parseDuration(variant.duration);

      // -- Route Doc --
      const routeRef = db.collection("routes").doc(routeId);
      batch.set(routeRef, {
        id: routeId,
        originCity: r.origin,
        destinationCity: r.dest,
        via: variant.via,
        stops: [r.origin, variant.via, r.dest], // Simple stop list
        distanceKm: Math.floor(durationMins * 0.7), // approximate
        estimatedDurationMins: durationMins,
        isActive: true,
      });
      opCount++;
      totalRoutes++;

      // -- Schedule Docs (Timed) --
      let timeIndex = 1;
      for (const time of TIMETABLE) {
        const scheduleId = `sch_${routeId}_${time.replace(":", "")}`;
        const serviceId = `${getCityCode(r.origin)}-${getCityCode(r.dest)}-${
          variant.code
        }-${timeIndex.toString().padStart(2, "0")}`;
        timeIndex++;

        // Schedule Data
        const scheduleData = {
          id: scheduleId,
          routeId: routeId,
          busNumber: serviceId, // Using the "Trip Name" from prompt as Bus ID/Service ID
          operatorName: "Buslink Official",
          busType: "Standard",
          amenities: ["AC", "Adjustable Seats"],
          recurrenceDays: [1, 2, 3, 4, 5, 6, 7], // Daily
          departureTime: time,
          basePrice: Number(variant.price),
          totalSeats: 40,
          conductorId: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const schRef = db.collection("schedules").doc(scheduleId);
        batch.set(schRef, scheduleData);
        opCount++;
        totalSchedules++;

        // -- Generate Trips (Next 30 Days) --
        // To avoid batch overflow (500 limit), we might need to commit inside this inner loop
        if (opCount > 300) {
          await batch.commit();
          batch = db.batch();
          opCount = 0;
        }

        const [depH, depM] = time.split(":").map(Number);

        for (let d = 0; d < DAYS_TO_GENERATE; d++) {
          const targetDate = new Date(today);
          targetDate.setDate(today.getDate() + d);
          const yyyymmdd = targetDate
            .toISOString()
            .split("T")[0]
            .replace(/-/g, "");
          const tripId = `trip_${scheduleId}_${yyyymmdd}`;

          const depDT = new Date(targetDate);
          depDT.setHours(depH, depM, 0, 0);

          // Arrival (+1 day awareness)
          const arrDT = new Date(depDT);
          arrDT.setMinutes(arrDT.getMinutes() + durationMins);

          const tripData = {
            id: tripId,
            scheduleId: scheduleId,
            date: admin.firestore.Timestamp.fromDate(targetDate),
            originCity: r.origin,
            destinationCity: r.dest,
            departureDateTime: admin.firestore.Timestamp.fromDate(depDT),
            arrivalDateTime: admin.firestore.Timestamp.fromDate(arrDT),
            price: Number(variant.price),
            status: "scheduled",
            totalSeats: 40,
            delayMinutes: 0,
            bookedSeatNumbers: [],
            // Extra display fields
            busNumber: serviceId,
            via: variant.via,
          };

          const tripRef = db.collection("trips").doc(tripId);
          batch.set(tripRef, tripData);
          opCount++;
          totalTrips++;

          if (opCount >= 450) {
            await batch.commit();
            batch = db.batch();
            opCount = 0;
          }
        }
      }
    }
  }

  if (opCount > 0) await batch.commit();

  console.log("------------------------------------------------");
  console.log(`🏁 SEED COMPLETE`);
  console.log(`   Routes: ${totalRoutes}`);
  console.log(`   Schedules: ${totalSchedules}`);
  console.log(`   Trips: ${totalTrips}`);
  console.log("------------------------------------------------");
}

seedMasterData().catch(console.error);
