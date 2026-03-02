const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");

// Initialize Firebase Admin SDK once.
admin.initializeApp();

// Set global region to avoid repeating it.
setGlobalOptions({region: "southamerica-east1"});

// Import domains (Feature-First Architecture)
const adminFeatures = require("./src/features/admin");
const eventsFeatures = require("./src/features/events");
const gameplayFeatures = require("./src/features/gameplay");
const paymentFeatures = require("./src/features/payments");
const homeFeatures = require("./src/features/users/home");
const walletFeatures = require("./src/features/users/wallet");
const notificationFeatures = require("./src/features/notifications");

// Export all functions cleanly
Object.assign(exports,
    adminFeatures,
    eventsFeatures,
    gameplayFeatures,
    paymentFeatures,
    homeFeatures,
    walletFeatures,
    notificationFeatures,
);
