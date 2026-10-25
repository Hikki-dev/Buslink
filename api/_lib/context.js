// The real Stripe, the real database and the real sign-in check. Made when
// first used, so a missing key only breaks the call that needs it.
const Stripe = require("stripe");
const admin = require("firebase-admin");
const { PaymentError } = require("./core");
const { makeHandlers } = require("./handlers");

let handlers;

function firebase() {
  if (admin.apps.length === 0) {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    if (!raw) throw new PaymentError(500, "Server misconfiguration: FIREBASE_SERVICE_ACCOUNT_BASE64 is missing.");
    const account = JSON.parse(Buffer.from(raw, "base64").toString("utf8"));
    admin.initializeApp({ credential: admin.credential.cert(account) });
  }
  return admin;
}

async function verifyUser(req) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  if (!token) return null;
  try {
    const decoded = await firebase().auth().verifyIdToken(token);
    return { uid: decoded.uid, email: decoded.email };
  } catch (e) {
    return null;
  }
}

function getHandlers() {
  if (!handlers) {
    if (!process.env.STRIPE_SECRET_KEY) {
      throw new PaymentError(500, "Server misconfiguration: STRIPE_SECRET_KEY is missing.");
    }
    handlers = makeHandlers({
      stripe: Stripe(process.env.STRIPE_SECRET_KEY),
      db: firebase().firestore(),
      verifyUser,
    });
  }
  return handlers;
}

/** The little wrapper every endpoint shares: CORS, method check, errors as JSON. */
function endpoint(run) {
  return async (req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "POST,OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, Stripe-Signature");
    if (req.method === "OPTIONS") return res.status(200).end();
    if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });
    try {
      return res.status(200).json(await run(getHandlers(), req));
    } catch (e) {
      if (e instanceof PaymentError) return res.status(e.status).json({ error: e.message });
      console.error("Payment endpoint error:", e);
      return res.status(500).json({ error: "Something went wrong on the server." });
    }
  };
}

module.exports = { endpoint, getHandlers };
