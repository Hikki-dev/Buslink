const { endpoint } = require("./_lib/context");

// Sends money back to a card. Admins only.
module.exports = endpoint((h, req) => h.refund(req, req.body || {}));
