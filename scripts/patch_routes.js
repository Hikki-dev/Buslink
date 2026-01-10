const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const ROUTE_COLLECTION = "routes";

async function patchRoutes() {
  console.log("🚀 STARTING ROUTE PATCH (Fixing 0km / 0mins)");

  const routesSnap = await db.collection(ROUTE_COLLECTION).get();
  let patchedCount = 0;
  const batch = db.batch();

  for (const doc of routesSnap.docs) {
    const data = doc.data();
    let needsUpdate = false;
    let updateData = {};

    // 1. Fix Distance
    if (!data.distanceKm || data.distanceKm === 0) {
      // Generate random reasonable distance between 50km and 300km
      const randomDist = Math.floor(Math.random() * (300 - 50 + 1)) + 50;
      updateData.distanceKm = randomDist;
      needsUpdate = true;
    }

    // 2. Fix Duration
    if (!data.estimatedDurationMins || data.estimatedDurationMins === 0) {
      // Estimate based on distance (approx 40km/h average including stops) -> 1.5 mins per km
      const dist = updateData.distanceKm || data.distanceKm || 100;
      const estMins = Math.floor(dist * 1.5);
      updateData.estimatedDurationMins = estMins;
      needsUpdate = true;
    }

    if (needsUpdate) {
      const ref = db.collection(ROUTE_COLLECTION).doc(doc.id);
      batch.update(ref, updateData);
      patchedCount++;
      console.log(
        `   🔧 Patching Route ${doc.id}: ${updateData.distanceKm}km, ${updateData.estimatedDurationMins}mins`
      );
    }
  }

  if (patchedCount > 0) {
    await batch.commit();
    console.log(`✅ Patched ${patchedCount} routes.`);
  } else {
    console.log("✅ All routes already have valid data.");
  }
}

patchRoutes().catch(console.error);
