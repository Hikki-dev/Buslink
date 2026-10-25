// The rules for taking and confirming a payment. Pure functions: no Stripe,
// no Firebase, no network, so they can be tested on their own.
//
// The idea: the server decides what a booking costs, the server asks Stripe
// whether it was paid, and only the server marks a ticket confirmed. The phone
// never says "I paid".

const CURRENCY = "lkr";

class PaymentError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

/** "a,b,c" or ["a","b"] -> ["a","b","c"], without blanks or repeats. */
function parseIds(value) {
  const list = Array.isArray(value) ? value : String(value || "").split(",");
  return [...new Set(list.map((s) => String(s).trim()).filter(Boolean))];
}

/** Rupees (can have decimals) -> the smallest unit Stripe wants (cents). */
function toCents(rupees) {
  return Math.round(Number(rupees) * 100);
}

/**
 * Checks that [tickets] (a map id -> data, undefined when missing) can be paid
 * for by [uid], and says how much it costs. Throws a PaymentError if not.
 */
function planCheckout(ids, tickets, uid) {
  if (ids.length === 0) throw new PaymentError(400, "No booking was given.");
  if (ids.length > 50) throw new PaymentError(400, "Too many bookings at once.");
  let rupees = 0;
  for (const id of ids) {
    const t = tickets[id];
    if (!t) throw new PaymentError(404, `Booking ${id} was not found.`);
    if (t.userId !== uid) throw new PaymentError(403, "That booking is not yours.");
    if (t.status !== "pending") {
      throw new PaymentError(409, "That booking is not waiting for payment.");
    }
    const price = Number(t.totalAmount);
    if (!(price > 0)) throw new PaymentError(409, "That booking has no price.");
    rupees += price;
  }
  const cents = toCents(rupees);
  // Stripe's own smallest charge is about 50 US cents, roughly LKR 165.
  if (cents < 15000) {
    throw new PaymentError(400, "Amount must be at least LKR 150 for online payment.");
  }
  return { ids, cents };
}

/**
 * [paid] describes what Stripe says: { paid: bool, cents, currency,
 * bookingIds: [..], paymentIntentId }. Decides which tickets to confirm.
 * [uid] is the signed-in person, or null when Stripe itself is calling (the
 * webhook). Throws a PaymentError if anything does not add up.
 */
function planConfirmation(ids, tickets, paid, uid) {
  if (ids.length === 0) throw new PaymentError(400, "No booking was given.");
  if (!paid.paid) throw new PaymentError(402, "Stripe has not received this payment yet.");
  if (paid.currency !== CURRENCY) throw new PaymentError(409, "Wrong currency.");

  // The payment was made for exactly these bookings, no more, no fewer.
  const forWhom = parseIds(paid.bookingIds);
  if (forWhom.length !== ids.length || !ids.every((id) => forWhom.includes(id))) {
    throw new PaymentError(409, "This payment is for different bookings.");
  }

  let rupees = 0;
  const toConfirm = [];
  for (const id of ids) {
    const t = tickets[id];
    if (!t) throw new PaymentError(404, `Booking ${id} was not found.`);
    if (uid && t.userId !== uid) throw new PaymentError(403, "That booking is not yours.");
    rupees += Number(t.totalAmount) || 0;
    if (t.status === "confirmed") {
      // Already done. Fine only if it was this same payment (a repeat call).
      if (t.paymentIntentId && t.paymentIntentId !== paid.paymentIntentId) {
        throw new PaymentError(409, "That booking was paid with a different payment.");
      }
      continue;
    }
    if (t.status !== "pending") {
      throw new PaymentError(409, "That booking cannot be confirmed any more.");
    }
    toConfirm.push(id);
  }
  if (toCents(rupees) !== paid.cents) {
    throw new PaymentError(409, "The amount paid does not match the bookings.");
  }
  return { toConfirm };
}

/** What Stripe's Checkout Session says, in the shape planConfirmation wants. */
function fromSession(session) {
  return {
    paid: session.payment_status === "paid",
    cents: session.amount_total,
    currency: session.currency,
    bookingIds: session.metadata && session.metadata.booking_ids,
    paymentIntentId:
      typeof session.payment_intent === "string"
        ? session.payment_intent
        : session.payment_intent && session.payment_intent.id,
  };
}

/** What Stripe's PaymentIntent says, in the same shape. */
function fromIntent(intent) {
  return {
    paid: intent.status === "succeeded",
    cents: intent.amount_received || intent.amount,
    currency: intent.currency,
    bookingIds: intent.metadata && intent.metadata.booking_ids,
    paymentIntentId: intent.id,
  };
}

module.exports = {
  PaymentError,
  parseIds,
  toCents,
  planCheckout,
  planConfirmation,
  fromSession,
  fromIntent,
  CURRENCY,
};
