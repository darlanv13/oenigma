const admin = require("firebase-admin");

/**
 * Logs an administrative action to Firestore.
 * @param {string} adminUid - The UID of the admin performing the action.
 * @param {string} action - A short string describing the action (e.g., 'approve_withdrawal', 'set_role').
 * @param {string} target - The target of the action (e.g., 'withdrawal_123', 'user_abc').
 * @param {object} details - Additional details about the action.
 */
async function logAdminAction(adminUid, action, target, details = {}) {
    try {
        await admin.firestore().collection('admin_logs').add({
            adminUid,
            action,
            target,
            details,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (error) {
        console.error("Failed to log admin action:", error);
    }
}

module.exports = {
    logAdminAction,
};
