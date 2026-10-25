// What each payment endpoint does, with everything outside the project
// (Stripe, the database, who is signed in) passed in. The real versions are in
// context.js; the tests pass in small fakes.
const {
  PaymentError,
  parseIds,
  planCheckout,
  planConfirmation,
  fromSession,
  fromIntent,
  CURRENCY,
} = require("./core");

const ADMIN_EMAIL = "admin@buslink.com"; // the same leftover admin the database rules know about

function makeHandlers({ stripe, db, verifyUser, now = () => new Date() }) {
  const tickets = () => db.collection("tickets");

  async function readTickets(ids) {
    const found = {};
    for (const id of ids) {
      const snap = await tickets().doc(id).get();
      if (snap.exists) found[id] = snap.data();
    }
    return found;
  }

  /** Marks tickets confirmed, in one transaction, after checking Stripe's answer. */
  async function confirmWith(ids, paid, uid) {
    return db.runTransaction(async (tx) => {
      const found = {};
      for (const id of ids) {
        const snap = await tx.get(tickets().doc(id));
        if (snap.exists) found[id] = snap.data();
      }
      const { toConfirm } = planConfirmation(ids, found, paid, uid);
      for (const id of toConfirm) {
        tx.update(tickets().doc(id), {
          status: "confirmed",
          paymentIntentId: paid.paymentIntentId || null,
          confirmedAt: now(),
        });
      }
      return { confirmed: toConfirm.length, alreadyConfirmed: ids.length - toConfirm.length };
    });
  }

  return {
    /** The person signed in. Throws 401 if nobody is. */
    async user(req) {
      const u = await verifyUser(req);
      if (!u || !u.uid) throw new PaymentError(401, "Please sign in.");
      return u;
    },

    /** Starts a Stripe Checkout page for bookings that are waiting for payment. */
    async checkout(req, body) {
      const { uid } = await this.user(req);
      const ids = parseIds(body.bookingIds);
      const { cents } = planCheckout(ids, await readTickets(ids), uid);
      if (!body.successUrl || !body.cancelUrl) {
        throw new PaymentError(400, "Missing successUrl or cancelUrl.");
      }
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency: CURRENCY,
              product_data: { name: "Bus Ticket Booking" },
              unit_amount: cents,
            },
            quantity: 1,
          },
        ],
        mode: "payment",
        success_url: body.successUrl,
        cancel_url: body.cancelUrl,
        client_reference_id: ids.join(","),
        metadata: { booking_ids: ids.join(","), uid },
      });
      return { url: session.url };
    },

    /** The phone app's payment sheet needs a PaymentIntent. */
    async paymentIntent(req, body) {
      const { uid } = await this.user(req);
      const ids = parseIds(body.bookingIds);
      const { cents } = planCheckout(ids, await readTickets(ids), uid);
      const intent = await stripe.paymentIntents.create({
        amount: cents,
        currency: CURRENCY,
        payment_method_types: ["card"],
        metadata: { booking_ids: ids.join(","), uid },
      });
      return { clientSecret: intent.client_secret, id: intent.id };
    },

    /** The page Stripe sends people back to calls this. Stripe is asked, not the phone. */
    async confirm(req, body) {
      const { uid } = await this.user(req);
      const ids = parseIds(body.bookingIds);
      let paid;
      if (body.sessionId) {
        paid = fromSession(await stripe.checkout.sessions.retrieve(String(body.sessionId)));
      } else if (body.paymentIntentId) {
        paid = fromIntent(await stripe.paymentIntents.retrieve(String(body.paymentIntentId)));
      } else {
        throw new PaymentError(400, "Give a sessionId or a paymentIntentId.");
      }
      return confirmWith(ids, paid, uid);
    },

    /** Stripe tells us itself, even if the passenger closed the page. */
    async webhook(rawBody, signature, secret) {
      if (!secret) throw new PaymentError(500, "STRIPE_WEBHOOK_SECRET is not set.");
      let event;
      try {
        event = stripe.webhooks.constructEvent(rawBody, signature, secret);
      } catch (e) {
        throw new PaymentError(400, "That did not come from Stripe.");
      }
      const paidTypes = ["checkout.session.completed", "checkout.session.async_payment_succeeded"];
      if (!paidTypes.includes(event.type)) return { ignored: event.type };
      const session = event.data.object;
      const ids = parseIds(session.metadata && session.metadata.booking_ids);
      if (ids.length === 0) return { ignored: "no bookings" };
      return confirmWith(ids, fromSession(session), null);
    },

    /** Money goes back to a card: admins only. */
    async refund(req, body) {
      const { uid, email } = await this.user(req);
      const profile = await db.collection("users").doc(uid).get();
      const isAdmin = (profile.exists && profile.data().role === "admin") || email === ADMIN_EMAIL;
      if (!isAdmin) throw new PaymentError(403, "Only an admin can refund a payment.");
      if (!body.paymentIntentId || !(Number(body.amount) > 0)) {
        throw new PaymentError(400, "Missing parameters: paymentIntentId or amount");
      }
      const refund = await stripe.refunds.create({
        payment_intent: String(body.paymentIntentId),
        amount: Math.round(Number(body.amount)),
      });
      return { success: true, id: refund.id, refund };
    },
  };
}

module.exports = { makeHandlers };
