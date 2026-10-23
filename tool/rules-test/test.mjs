import fs from 'fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, getDoc, addDoc, collection, serverTimestamp, arrayUnion } from 'firebase/firestore';

// By default the tests run against the repository's own firestore.rules.
// Set RULES=/path/to/other.rules to try a different file.
const rules = fs.readFileSync(process.env.RULES || '../../firestore.rules', 'utf8');
const env = await initializeTestEnvironment({
  projectId: 'demo-buslink',
  firestore: { rules, host: '127.0.0.1', port: 8089 },
});

async function seed() {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/p1'), { uid: 'p1', role: 'customer', email: 'p1@x.com' });
    await setDoc(doc(db, 'users/p2'), { uid: 'p2', role: 'customer', email: 'p2@x.com' });
    await setDoc(doc(db, 'users/c1'), { uid: 'c1', role: 'conductor', email: 'c1@x.com' });
    await setDoc(doc(db, 'users/a1'), { uid: 'a1', role: 'admin', email: 'a1@x.com' });
    await setDoc(doc(db, 'trips/t1'), { price: 1200, status: 'scheduled', bookedSeatNumbers: [] });
    await setDoc(doc(db, 'tickets/tk1'), { userId: 'p1', tripId: 't1', status: 'pending', totalAmount: 1200, seatNumbers: [1] });
    await setDoc(doc(db, 'tickets/tk2'), { userId: 'p2', tripId: 't1', status: 'confirmed', totalAmount: 1200, seatNumbers: [2] });
    await setDoc(doc(db, 'tickets/tk3'), { userId: 'p2', tripId: 't1', status: 'confirmed', totalAmount: 1200, seatNumbers: [3], boardedAt: new Date(), boardedBy: 'c1' });
  });
}

const as = (uid, email) => env.authenticatedContext(uid, email ? { email } : {}).firestore();
const anon = () => env.unauthenticatedContext().firestore();

// [name, who, action, expected for the NEW rules]
const cases = [
  ['passenger creates own profile as customer', 'p3', (d) => setDoc(doc(d, 'users/p3'), { uid: 'p3', role: 'customer' }), true],
  ['passenger creates own profile as ADMIN', 'p4', (d) => setDoc(doc(d, 'users/p4'), { uid: 'p4', role: 'admin' }), false],
  ['passenger promotes themselves to admin', 'p1', (d) => updateDoc(doc(d, 'users/p1'), { role: 'admin' }), false],
  ['passenger edits own name', 'p1', (d) => updateDoc(doc(d, 'users/p1'), { displayName: 'Nimal' }), true],
  ['passenger edits SOMEONE ELSE', 'p1', (d) => updateDoc(doc(d, 'users/p2'), { displayName: 'x' }), false],
  ['passenger writes own favourite route', 'p1', (d) => setDoc(doc(d, 'users/p1/favorite_routes/r1'), { from: 'A' }), true],
  ['passenger books seats (trip seat list)', 'p1', (d) => updateDoc(doc(d, 'trips/t1'), { bookedSeatNumbers: arrayUnion('5') }), true],
  ['passenger changes trip price', 'p1', (d) => updateDoc(doc(d, 'trips/t1'), { price: 1 }), false],
  ['passenger creates own ticket', 'p1', (d) => setDoc(doc(d, 'tickets/new1'), { userId: 'p1', tripId: 't1', status: 'pending', totalAmount: 1200, seatNumbers: [9] }), true],
  ['passenger creates ticket for someone else', 'p1', (d) => setDoc(doc(d, 'tickets/new2'), { userId: 'p2', tripId: 't1' }), false],
  ['passenger confirms own ticket (payment)', 'p1', (d) => updateDoc(doc(d, 'tickets/tk1'), { status: 'confirmed', paymentIntentId: 'pi_1' }), true],
  ['passenger asks refund: ticket status', 'p2', (d) => updateDoc(doc(d, 'tickets/tk2'), { status: 'refund_requested' }), true],
  ['passenger marks own ticket BOARDED', 'p1', (d) => updateDoc(doc(d, 'tickets/tk1'), { boardedAt: new Date(), boardedBy: 'p1' }), false],
  ['passenger lowers own ticket price', 'p1', (d) => updateDoc(doc(d, 'tickets/tk1'), { totalAmount: 1 }), false],
  ['passenger changes own ticket seats', 'p1', (d) => updateDoc(doc(d, 'tickets/tk1'), { seatNumbers: [1, 2, 3] }), false],
  ['passenger updates SOMEONE ELSE ticket', 'p1', (d) => updateDoc(doc(d, 'tickets/tk2'), { status: 'cancelled' }), false],
  ['passenger reads own ticket', 'p1', (d) => getDoc(doc(d, 'tickets/tk1')), true],
  ['passenger reads SOMEONE ELSE ticket', 'p1', (d) => getDoc(doc(d, 'tickets/tk2')), false],
  ['passenger files a refund for self', 'p1', (d) => setDoc(doc(d, 'refunds/rf1'), { userId: 'p1', ticketId: 'tk1', status: 'pending' }), true],
  ['passenger approves own refund', 'p1', (d) => updateDoc(doc(d, 'refunds/rf1'), { status: 'approved' }), false],
  ['passenger makes own notification (refund received)', 'p1', (d) => addDoc(collection(d, 'notifications'), { userId: 'p1', title: 't' }), true],
  ['passenger sends feedback', 'p1', (d) => addDoc(collection(d, 'feedback'), { text: 'hi' }), true],
  ['passenger reads feedback', 'p1', (d) => getDoc(doc(d, 'feedback/zzz')), false],
  ['conductor reads a passenger profile', 'c1', (d) => getDoc(doc(d, 'users/p1')), true],
  ['conductor reads a ticket', 'c1', (d) => getDoc(doc(d, 'tickets/tk1')), true],
  ['conductor boards a fresh ticket', 'c1', (d) => updateDoc(doc(d, 'tickets/tk1'), { boardedAt: serverTimestamp(), boardedBy: 'c1' }), true],
  ['conductor boards an ALREADY boarded ticket', 'c1', (d) => updateDoc(doc(d, 'tickets/tk3'), { boardedAt: serverTimestamp(), boardedBy: 'c1' }), false],
  ['conductor clears a boarding', 'c1', (d) => updateDoc(doc(d, 'tickets/tk3'), { boardedAt: null }), false],
  ['conductor boards as SOMEONE ELSE', 'c1', (d) => updateDoc(doc(d, 'tickets/tk2'), { boardedAt: serverTimestamp(), boardedBy: 'a1' }), false],
  ['conductor edits another ticket field (as today)', 'c1', (d) => updateDoc(doc(d, 'tickets/tk2'), { status: 'cancelled' }), true],
  ['conductor makes walk-up booking', 'c1', (d) => setDoc(doc(d, 'tickets/off1'), { userId: 'c1', tripId: 't1', status: 'confirmed' }), true],
  ['conductor reports delay (trip)', 'c1', (d) => updateDoc(doc(d, 'trips/t1'), { delayMinutes: 30, status: 'delayed' }), true],
  ['conductor notifies a passenger of delay', 'c1', (d) => addDoc(collection(d, 'notifications'), { userId: 'p1', title: 'delay' }), true],
  ['conductor creates a trip', 'c1', (d) => setDoc(doc(d, 'trips/t9'), { price: 1 }), false],
  ['conductor makes themselves admin', 'c1', (d) => updateDoc(doc(d, 'users/c1'), { role: 'admin' }), false],
  ['admin sets a role', 'a1', (d) => updateDoc(doc(d, 'users/p2'), { role: 'conductor' }), true],
  ['admin edits any ticket', 'a1', (d) => updateDoc(doc(d, 'tickets/tk2'), { status: 'refunded' }), true],
  ['admin creates a trip', 'a1', (d) => setDoc(doc(d, 'trips/t8'), { price: 1 }), true],
  ['admin approves a refund', 'a1', (d) => updateDoc(doc(d, 'refunds/rf9'), { status: 'approved' }), true, async (db) => setDoc(doc(db, 'refunds/rf9'), { userId: 'p1', status: 'pending' })],
  ['admin reads feedback', 'a1', (d) => getDoc(doc(d, 'feedback/zzz')), true],
  ['anyone reads trips', null, (d) => getDoc(doc(d, 'trips/t1')), true],
  ['signed-out reads a ticket', null, (d) => getDoc(doc(d, 'tickets/tk1')), false],
  ['signed-out reads a profile', null, (d) => getDoc(doc(d, 'users/p1')), false],
];

let wrong = 0;
for (const [name, who, run, expected, pre] of cases) {
  await seed();
  if (pre) await env.withSecurityRulesDisabled(async (c) => pre(c.firestore()));
  const db = who ? as(who, who === 'a1' ? 'a1@x.com' : undefined) : anon();
  let ok;
  try { await run(db); ok = true; } catch { ok = false; }
  const flag = ok === expected ? 'ok   ' : 'DIFF ';
  if (ok !== expected) wrong++;
  console.log(`${flag}${ok ? 'allowed' : 'DENIED '}  (want ${expected ? 'allowed' : 'DENIED '})  ${name}`);
}
console.log(`\n${cases.length} cases, ${wrong} differ from the wanted result`);
await env.cleanup();
if (wrong > 0) process.exit(1);
