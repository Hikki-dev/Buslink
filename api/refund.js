const Stripe = require("stripe");

// Initialize Stripe with the Secret Key from environment variables
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

module.exports = async (req, res) => {
  // 1. Enable CORS
  res.setHeader("Access-Control-Allow-Credentials", true);
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET,OPTIONS,PATCH,DELETE,POST,PUT"
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version"
  );

  // Handle OPTIONS method for CORS preflight
  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  // 2. Validate Request Method
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  try {
    const { paymentIntentId, amount } = req.body;

    if (!paymentIntentId || !amount) {
      return res
        .status(400)
        .json({ error: "Missing parameters: paymentIntentId or amount" });
    }

    // 3. Process Refund
    // Amount is passed as integer cents (e.g., 5000 for 50.00)
    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount,
    });

    return res.status(200).json({ success: true, refund });
  } catch (error) {
    console.error("Stripe Refund Error:", error);
    return res.status(500).json({ error: error.message });
  }
};
