// Run with:  node --test api/_lib
// No packages needed: Stripe and the database are small fakes.
const test = require("node:test");
const assert = require("node:assert/strict");
const { PaymentError, planCheckout, planConfirmation, toCents, parseIds } = require("./core");
const { makeHandlers } = require("./handlers");

const mk = (over = {}) => ({ userId: "p1", status: "pending", totalAmount: 1200, ...over });

// ---- the rules on their own ----

test("parseIds tidies a list", () => {
  assert.deepEqual(parseIds("a, b,,a"), ["a", "b"]);
  assert.deepEqual(parseIds(["x", " y "]), ["x", "y"]);
  assert.deepEqual(parseIds(undefined), []);
});

test("toCents rounds money", () => {
  assert.equal(toCents(1200), 120000);
  assert.equal(toCents(19.99), 1999);
});

test("checkout: the price is the bookings' price, summed", () => {
  const plan = planCheckout(["a", "b"], { a: mk(), b: mk({ totalAmount: 800 }) }, "p1");
  assert.equal(plan.cents, 200000);
});

test("checkout refuses someone else's booking, a paid one, a missing one and a tiny amount", () => {
  assert.throws(() => planCheckout(["a"], { a: mk({ userId: "p2" }) }, "p1"), { status: 403 });
  assert.throws(() => planCheckout(["a"], { a: mk({ status: "confirmed" }) }, "p1"), { status: 409 });
  assert.throws(() => planCheckout(["a"], {}, "p1"), { status: 404 });
  assert.throws(() => planCheckout(["a"], { a: mk({ totalAmount: 100 }) }, "p1"), { status: 400 });
  assert.throws(() => planCheckout([], {}, "p1"), { status: 400 });
});

const paid = (over = {}) => ({ paid: true, cents: 120000, currency: "lkr", bookingIds: "a", paymentIntentId: "pi_1", ...over });

test("confirmation: a real, matching payment confirms", () => {
  assert.deepEqual(planConfirmation(["a"], { a: mk() }, paid(), "p1").toConfirm, ["a"]);
});

test("confirmation refuses an unpaid, mismatched, mis-priced or foreign payment", () => {
  const t = { a: mk() };
  assert.throws(() => planConfirmation(["a"], t, paid({ paid: false }), "p1"), { status: 402 });
  assert.throws(() => planConfirmation(["a"], t, paid({ currency: "usd" }), "p1"), { status: 409 });
  assert.throws(() => planConfirmation(["a"], t, paid({ bookingIds: "b" }), "p1"), { status: 409 });
  assert.throws(() => planConfirmation(["a"], t, paid({ bookingIds: "a,b" }), "p1"), { status: 409 });
  assert.throws(() => planConfirmation(["a"], t, paid({ cents: 100 }), "p1"), { status: 409 });
  assert.throws(() => planConfirmation(["a"], { a: mk({ userId: "p2" }) }, paid(), "p1"), { status: 403 });
});

test("confirmation is safe to repeat, but not with a different payment", () => {
  const done = { a: mk({ status: "confirmed", paymentIntentId: "pi_1" }) };
  assert.deepEqual(planConfirmation(["a"], done, paid(), "p1").toConfirm, []);
  assert.throws(() => planConfirmation(["a"], done, paid({ paymentIntentId: "pi_2" }), "p1"), { status: 409 });
  assert.throws(() => planConfirmation(["a"], { a: mk({ status: "cancelled" }) }, paid(), "p1"), { status: 409 });
});

test("the webhook (no signed-in person) can confirm anyone's booking that was paid", () => {
  assert.deepEqual(planConfirmation(["a"], { a: mk({ userId: "p9" }) }, paid(), null).toConfirm, ["a"]);
});

// ---- the endpoints, with a fake database and a fake Stripe ----

function fakeDb(data) {
  const store = new Map(Object.entries(data));
  const ref = (path) => ({ path });
  const snap = (path) => ({ exists: store.has(path), data: () => store.get(path) });
  return {
    store,
    collection: (c) => ({ doc: (id) => ({ path: `${c}/${id}`, get: async () => snap(`${c}/${id}`) }) }),
    runTransaction: async (fn) => {
      const writes = [];
      const result = await fn({
        get: async (r) => snap(r.path),
        update: (r, d) => writes.push([r.path, d]),
      });
      for (const [p, d] of writes) store.set(p, { ...store.get(p), ...d });
      return result;
    },
  };
}

function setup({ tickets, session, intent, users = {} } = {}) {
  const db = fakeDb({ ...Object.fromEntries(Object.entries(tickets || {}).map(([k, v]) => [`tickets/${k}`, v])), ...users });
  const calls = { sessions: [], intents: [], refunds: [] };
  const stripe = {
    checkout: {
      sessions: {
        create: async (p) => (calls.sessions.push(p), { url: "https://checkout.test/s" }),
        retrieve: async () => session,
      },
    },
    paymentIntents: {
      create: async (p) => (calls.intents.push(p), { client_secret: "pi_9_secret_x", id: "pi_9" }),
      retrieve: async () => intent,
    },
    refunds: { create: async (p) => (calls.refunds.push(p), { id: "re_1" }) },
    webhooks: {
      constructEvent: (body, sig) => {
        if (sig !== "good") throw new Error("bad signature");
        return JSON.parse(body.toString());
      },
    },
  };
  let signedIn = { uid: "p1", email: "p1@x.com" };
  const h = makeHandlers({ stripe, db, verifyUser: async () => signedIn, now: () => new Date(0) });
  return { h, db, calls, signIn: (u) => (signedIn = u) };
}

test("checkout takes the price from the database and ignores what the phone says", async () => {
  const { h, calls } = setup({ tickets: { a: mk() } });
  const out = await h.checkout({}, { bookingIds: "a", amount: 1, successUrl: "https://x/ok", cancelUrl: "https://x/no" });
  assert.equal(out.url, "https://checkout.test/s");
  assert.equal(calls.sessions[0].line_items[0].price_data.unit_amount, 120000);
  assert.equal(calls.sessions[0].metadata.booking_ids, "a");
});

test("nobody signed in gets 401", async () => {
  const { h, signIn } = setup({ tickets: { a: mk() } });
  signIn(null);
  await assert.rejects(h.checkout({}, { bookingIds: "a", successUrl: "u", cancelUrl: "u" }), { status: 401 });
});

test("a passenger cannot pay for, or confirm, someone else's booking", async () => {
  const { h } = setup({ tickets: { a: mk({ userId: "p2" }) } });
  await assert.rejects(h.checkout({}, { bookingIds: "a", successUrl: "u", cancelUrl: "u" }), { status: 403 });
});

test("confirm marks the ticket confirmed only when Stripe says it was paid", async () => {
  const session = { payment_status: "paid", amount_total: 120000, currency: "lkr", metadata: { booking_ids: "a" }, payment_intent: "pi_1" };
  const { h, db } = setup({ tickets: { a: mk() }, session });
  const out = await h.confirm({}, { bookingIds: "a", sessionId: "cs_1" });
  assert.deepEqual(out, { confirmed: 1, alreadyConfirmed: 0 });
  assert.equal(db.store.get("tickets/a").status, "confirmed");
  assert.equal(db.store.get("tickets/a").paymentIntentId, "pi_1");
});

test("confirm leaves the ticket alone when the payment is not paid", async () => {
  const session = { payment_status: "unpaid", amount_total: 120000, currency: "lkr", metadata: { booking_ids: "a" } };
  const { h, db } = setup({ tickets: { a: mk() }, session });
  await assert.rejects(h.confirm({}, { bookingIds: "a", sessionId: "cs_1" }), { status: 402 });
  assert.equal(db.store.get("tickets/a").status, "pending");
});

test("one paid session cannot confirm a different booking", async () => {
  const session = { payment_status: "paid", amount_total: 120000, currency: "lkr", metadata: { booking_ids: "a" }, payment_intent: "pi_1" };
  const { h, db } = setup({ tickets: { a: mk(), b: mk() }, session });
  await assert.rejects(h.confirm({}, { bookingIds: "b", sessionId: "cs_1" }), { status: 409 });
  assert.equal(db.store.get("tickets/b").status, "pending");
});

test("confirm works for the phone's PaymentIntent too, and for several bookings", async () => {
  const intent = { id: "pi_2", status: "succeeded", amount: 200000, currency: "lkr", metadata: { booking_ids: "a,b" } };
  const { h, db } = setup({ tickets: { a: mk(), b: mk({ totalAmount: 800 }) }, intent });
  const out = await h.confirm({}, { bookingIds: "a,b", paymentIntentId: "pi_2" });
  assert.equal(out.confirmed, 2);
  assert.equal(db.store.get("tickets/b").status, "confirmed");
});

test("the webhook rejects a bad signature and confirms a paid session", async () => {
  const session = { payment_status: "paid", amount_total: 120000, currency: "lkr", metadata: { booking_ids: "a" }, payment_intent: "pi_1" };
  const { h, db } = setup({ tickets: { a: mk() } });
  const event = Buffer.from(JSON.stringify({ type: "checkout.session.completed", data: { object: session } }));
  await assert.rejects(h.webhook(event, "forged", "whsec"), { status: 400 });
  assert.equal(db.store.get("tickets/a").status, "pending");
  await h.webhook(event, "good", "whsec");
  assert.equal(db.store.get("tickets/a").status, "confirmed");
  const other = Buffer.from(JSON.stringify({ type: "charge.refunded", data: { object: {} } }));
  assert.deepEqual(await h.webhook(other, "good", "whsec"), { ignored: "charge.refunded" });
});

test("only an admin can refund", async () => {
  const { h, calls, signIn } = setup({ users: { "users/p1": { role: "customer" }, "users/a1": { role: "admin" } } });
  await assert.rejects(h.refund({}, { paymentIntentId: "pi_1", amount: 5000 }), { status: 403 });
  signIn({ uid: "a1", email: "a1@x.com" });
  const out = await h.refund({}, { paymentIntentId: "pi_1", amount: 5000 });
  assert.equal(out.success, true);
  assert.deepEqual(calls.refunds[0], { payment_intent: "pi_1", amount: 5000 });
  await assert.rejects(h.refund({}, { paymentIntentId: "pi_1" }), { status: 400 });
});

test("PaymentError carries its status", () => {
  assert.equal(new PaymentError(418, "x").status, 418);
});
