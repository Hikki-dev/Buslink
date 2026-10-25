const { endpoint } = require("./_lib/context");

// A PaymentIntent for the phone app's payment sheet. Same rules as checkout.
module.exports = endpoint((h, req) => h.paymentIntent(req, req.body || {}));
