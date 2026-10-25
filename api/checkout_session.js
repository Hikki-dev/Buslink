const { endpoint } = require("./_lib/context");

// Starts Stripe Checkout. The price comes from the bookings in the database,
// never from the request. Needs a signed-in passenger who owns the bookings.
module.exports = endpoint((h, req) => h.checkout(req, req.body || {}));
