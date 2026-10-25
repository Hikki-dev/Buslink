const { PaymentError } = require("./_lib/core");
const { getHandlers } = require("./_lib/context");

// Stripe calls this when a payment completes, even if the passenger closed the
// page before coming back. In the Stripe dashboard add an endpoint for
// https://YOUR-SITE/api/stripe_webhook with the events
// checkout.session.completed and checkout.session.async_payment_succeeded,
// and put its signing secret in STRIPE_WEBHOOK_SECRET.
function raw(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

module.exports = async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });
  try {
    const body = await raw(req);
    const result = await getHandlers().webhook(
      body,
      req.headers["stripe-signature"],
      process.env.STRIPE_WEBHOOK_SECRET,
    );
    return res.status(200).json(result);
  } catch (e) {
    if (e instanceof PaymentError) return res.status(e.status).json({ error: e.message });
    console.error("Stripe webhook error:", e);
    return res.status(500).json({ error: "Something went wrong on the server." });
  }
};

// Stripe signs the exact bytes it sends, so the body must not be parsed first.
module.exports.config = { api: { bodyParser: false } };
