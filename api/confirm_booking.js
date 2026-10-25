const { endpoint } = require("./_lib/context");

// Marks bookings confirmed, but only after asking Stripe whether they were paid
// (and for how much, and for which bookings).
module.exports = endpoint((h, req) => h.confirm(req, req.body || {}));
