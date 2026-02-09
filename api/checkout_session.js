const Stripe = require("stripe");

// Initialize Stripe with the Secret Key from environment variables
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

module.exports = async (req, res) => {
  // 1. Enable CORS
  res.setHeader("Access-Control-Allow-Credentials", true);
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET,OPTIONS,PATCH,DELETE,POST,PUT",
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version",
  );

  // Handle OPTIONS method for CORS preflight
  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  if (!process.env.STRIPE_SECRET_KEY) {
    console.error("Missing STRIPE_SECRET_KEY in environment variables");
    return res
      .status(500)
      .json({ error: "Server Misconfiguration: Missing STRIPE_SECRET_KEY" });
  }

  // 2. Validate Request Method
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  try {
    const { amount, currency, bookingId, successUrl, cancelUrl } = req.body;

    if (!amount || !currency || !successUrl || !cancelUrl) {
      return res.status(400).json({
        error:
          "Missing required parameters: amount, currency, successUrl, cancelUrl",
      });
    }

    // Convert amount to integer cents (e.g. 500 for 5.00) if it came as string "500" or number
    const unitAmount = parseInt(amount);

    // 3. Create Checkout Session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      line_items: [
        {
          price_data: {
            currency: currency,
            product_data: {
              name: "Bus Ticket Booking",
              metadata: {
                bookingId: bookingId,
              },
            },
            unit_amount: unitAmount,
          },
          quantity: 1,
        },
      ],
      mode: "payment",
      success_url: successUrl,
      cancel_url: cancelUrl,
      client_reference_id: bookingId,
    });

    return res.status(200).json({ url: session.url });
  } catch (error) {
    console.error("Stripe Checkout Session Error:", error);
    return res.status(500).json({ error: error.message });
  }
};
