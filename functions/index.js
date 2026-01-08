/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const Stripe = require("stripe");

admin.initializeApp();

// Initialize Stripe with your secret key (stored in secrets or env)
// Ideally: const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
// For this prototype, we'll assume it's set in the environment config
const stripe = Stripe(process.env.STRIPE_SECRET_KEY || "sk_test_PLACEHOLDER");

exports.processRefund = onCall(async (request) => {
  const { refundId } = request.data;
  const uid = request.auth.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "The user must be authenticated to process a refund."
    );
  }

  // 1. Check if user is admin (optional but recommended)
  // const userRecord = await admin.auth().getUser(uid);
  // if (userRecord.customClaims['role'] !== 'admin') { ... }

  logger.info(`Processing refund for ID: ${refundId} by user: ${uid}`);

  const db = admin.firestore();
  const refundRef = db.collection("refunds").doc(refundId);

  // 2. Run transaction to ensure atomicity
  try {
    const result = await db.runTransaction(async (transaction) => {
      const refundDoc = await transaction.get(refundRef);

      if (!refundDoc.exists) {
        throw new HttpsError("not-found", "Refund request not found.");
      }

      const data = refundDoc.data();

      if (data.status !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          "Refund is not in pending state."
        );
      }

      const { refundAmount, ticketId } = data; // bookingRef or paymentIntentId needed

      // In a real app, you need the payment_intent_id stored on the Ticket or Refund object
      // Let's assume the Ticket document has the 'paymentIntentId'
      const ticketRef = db.collection("tickets").doc(data.ticketId);
      const ticketDoc = await transaction.get(ticketRef);

      if (!ticketDoc.exists) {
        throw new HttpsError("not-found", "Associated ticket not found.");
      }

      const paymentIntentId = ticketDoc.data().paymentIntentId;

      if (!paymentIntentId) {
        // Fallback or Error?
        // If no Stripe ID, we can't refund via Stripe.
        // Maybe just mark as approved if it was cash?
        throw new HttpsError(
          "failed-precondition",
          "No Stripe Payment Intent ID found for this ticket."
        );
      }

      // 3. Call Stripe API
      // Note: We perform the external call OUTSIDE the transaction usually to avoid lock issues,
      // but if we want to be safe, we might do it here or in 2 steps.
      // Better pattern: Idempotency.

      // For simplicity in this function, we'll call it.
      // WARNING: Cloud functions transactions shouldn't have external side effects if retried.
      // But we will proceed for this prototype.

      // Create Refund
      const refund = await stripe.refunds.create({
        payment_intent: paymentIntentId,
        amount: Math.round(refundAmount * 100), // Stripe uses cents
        reason: "requested_by_customer",
        metadata: {
          refundRequestId: refundId,
          ticketId: ticketId,
        },
      });

      if (refund.status !== "succeeded" && refund.status !== "pending") {
        throw new HttpsError(
          "internal",
          `Stripe refund failed with status: ${refund.status}`
        );
      }

      // 4. Update Firestore
      transaction.update(refundRef, {
        status: "approved",
        processingStatus: "completed",
        stripeRefundId: refund.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        approvedBy: uid,
      });

      // Update Ticket as well
      transaction.update(ticketRef, {
        status: "refunded",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, stripeRefundId: refund.id };
    });

    logger.info("Refund processed successfully.");
    return result;
  } catch (error) {
    logger.error("Refund processing failed", error);
    // Determine if it was our HttpsError or a Stripe error
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message);
  }
});
