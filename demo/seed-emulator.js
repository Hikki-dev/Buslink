// Fills the LOCAL Firebase emulators with demo accounts and bookings, on top of the
// routes, schedules and trips made by scripts/seed_master_data.js and generate_trips.js.
// See docs/Demo mode.md. It never talks to a real Firebase project.
//
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//   GCLOUD_PROJECT=demo-buslink NODE_PATH=scripts/node_modules node demo/seed-emulator.js
// Normally you run bash demo/seed.sh, which does all of this.
const admin = require('firebase-admin');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST first. This script only works on the emulators.');
  process.exit(1);
}
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-buslink' });
const db = admin.firestore();
const auth = admin.auth();
const { Timestamp, FieldValue } = admin.firestore;

const PASSWORD = 'demo-password';
const PEOPLE = [
  { key: 'admin', email: 'admin@buslink.demo', name: 'Demo Admin', role: 'admin', phone: '+94770000001' },
  { key: 'conductor', email: 'conductor@buslink.demo', name: 'Sunil Conductor', role: 'conductor', phone: '+94770000002' },
  { key: 'customer', email: 'customer@buslink.demo', name: 'Nimali Perera', role: 'customer', phone: '+94770000003' },
  { key: 'customer2', email: 'kasun@buslink.demo', name: 'Kasun Silva', role: 'customer', phone: '+94770000004' },
];

const shortId = () => Math.random().toString(36).slice(2, 8).toUpperCase();
const seats = (n, taken) => { const out = []; while (out.length < n) { const s = String(1 + Math.floor(Math.random() * 40)); if (!taken.includes(s) && !out.includes(s)) out.push(s); } return out; };

async function user(p) {
  let rec;
  try { rec = await auth.getUserByEmail(p.email); } catch { rec = await auth.createUser({ email: p.email, password: PASSWORD, displayName: p.name, emailVerified: true }); }
  await db.collection('users').doc(rec.uid).set({
    uid: rec.uid, email: p.email, displayName: p.name, role: p.role, phoneNumber: p.phone, createdAt: Timestamp.now(), language: 'en',
  });
  return { ...p, uid: rec.uid };
}

async function findTrip(origin, dest, daysAhead, hour) {
  const d = new Date(); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() + daysAhead);
  const next = new Date(d); next.setDate(next.getDate() + 1);
  const snap = await db.collection('trips').where('originCity', '==', origin).where('destinationCity', '==', dest)
    .where('departureDateTime', '>=', Timestamp.fromDate(d)).where('departureDateTime', '<', Timestamp.fromDate(next)).get();
  const docs = snap.docs.sort((a, b) => a.data().departureDateTime.toMillis() - b.data().departureDateTime.toMillis());
  return docs.find((x) => x.data().departureDateTime.toDate().getHours() >= hour) || docs[0];
}

async function book(trip, person, n, status, extra = {}) {
  const t = trip.data();
  const taken = t.bookedSeatNumbers || [];
  const mine = seats(n, taken);
  const ref = db.collection('tickets').doc();
  const tripData = { ...t, id: trip.id };
  await db.runTransaction(async (tx) => {
    tx.update(trip.ref, { bookedSeatNumbers: FieldValue.arrayUnion(...mine) });
    tx.set(ref, {
      ticketId: ref.id, tripId: trip.id, userId: person.uid, seatNumbers: mine.map(Number), userName: person.name,
      passengerPhone: person.phone, passengerEmail: person.email, bookingTime: Timestamp.now(),
      totalAmount: (t.price || 0) * n, tripData, status, shortId: shortId(), paymentIntentId: status === 'pending' ? null : 'pi_demo_' + shortId(),
      userData: { name: person.name, email: person.email, phone: person.phone }, ...extra,
    });
  });
  return { id: ref.id, seats: mine, total: (t.price || 0) * n };
}

(async () => {
  const who = {};
  for (const p of PEOPLE) who[p.key] = await user(p);
  console.log('accounts ready (password for all:', PASSWORD + ')');

  // make the buses look lived-in: scatter some taken seats over the next three days
  for (const [o, d] of [['Colombo', 'Kandy'], ['Colombo', 'Galle'], ['Kandy', 'Colombo']]) {
    for (let day = 0; day < 3; day++) {
      const d0 = new Date(); d0.setHours(0, 0, 0, 0); d0.setDate(d0.getDate() + day);
      const d1 = new Date(d0); d1.setDate(d1.getDate() + 1);
      const snap = await db.collection('trips').where('originCity', '==', o).where('destinationCity', '==', d)
        .where('departureDateTime', '>=', Timestamp.fromDate(d0)).where('departureDateTime', '<', Timestamp.fromDate(d1)).get();
      for (const t of snap.docs) {
        const n = 4 + Math.floor(Math.random() * 22);
        await t.ref.update({ bookedSeatNumbers: seats(n, []) });
      }
    }
  }

  // the conductor drives some of tomorrow's trips
  const tomorrow = await findTrip('Colombo', 'Kandy', 1, 8);
  if (tomorrow) await tomorrow.ref.update({ conductorId: who.conductor.uid });

  const upcoming = await findTrip('Colombo', 'Kandy', 1, 8);
  const galle = await findTrip('Colombo', 'Galle', 4, 7);
  const back = await findTrip('Kandy', 'Colombo', 3, 16);
  const past = await findTrip('Colombo', 'Kandy', 0, 0);
  const made = [];
  if (upcoming) made.push(['upcoming', await book(upcoming, who.customer, 2, 'confirmed')]);
  if (galle) made.push(['galle', await book(galle, who.customer, 1, 'confirmed')]);
  if (back) made.push(['back', await book(back, who.customer, 3, 'confirmed')]);
  if (past) made.push(['past', await book(past, who.customer2, 1, 'confirmed')]);

  // a refund waiting for the admin, and one already processed
  const t0 = made.find((m) => m[0] === 'galle');
  const t1 = made.find((m) => m[0] === 'back');
  const mkRefund = (m, who_, status, reason, pct) => db.collection('refunds').add({
    bookingId: m[1].id, ticketId: m[1].id, tripId: '', userId: who_.uid, passengerName: who_.name, passengerPhone: who_.phone, email: who_.email,
    requestedAt: Timestamp.now(), createdAt: Timestamp.now(), updatedAt: Timestamp.now(), amountRequested: m[1].total, tripPrice: m[1].total,
    refundPercentage: pct, refundAmount: Math.round(m[1].total * pct / 100), cancellationFee: Math.round(m[1].total * (100 - pct) / 100),
    status, reason, otherReasonText: null, userData: { name: who_.name, email: who_.email, phone: who_.phone },
  });
  if (t0) await mkRefund(t0, who.customer, 'pending', 'changeOfPlans', 80);
  if (t1) await mkRefund(t1, who.customer, 'processed', 'personalEmergency', 100);

  for (const f of [
    { u: who.customer, rating: 5, comment: 'Booked a seat in under a minute and the QR ticket worked first time.' },
    { u: who.customer2, rating: 4, comment: 'Love the seat map. Would like to see the bus photo before I pay.' },
    { u: who.customer, rating: 5, comment: 'The refund request was answered the same day.' },
  ]) {
    await db.collection('feedback').add({ userId: f.u.uid, userName: f.u.name, userEmail: f.u.email, rating: f.rating, comment: f.comment, timestamp: Timestamp.now(), platform: 'web' });
  }
  console.log('bookings:', made.map((m) => m[0] + ' ' + m[1].id).join(', '));
  console.log('Done. Sign in as admin@buslink.demo, conductor@buslink.demo or customer@buslink.demo with', PASSWORD);
})().catch((e) => { console.error(e); process.exit(1); });
