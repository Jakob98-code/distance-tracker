const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a new notification is written to:
 *   /couples/{coupleId}/notifications/{notifId}
 *
 * Looks up the target partner's FCM token and sends a push notification.
 */
exports.sendPushNotification = functions
  .region("europe-west1")
  .database.ref("/couples/{coupleId}/notifications/{notifId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.val();
    const { coupleId } = context.params;

    if (!data || !data.to || !data.message) {
      console.log("Invalid notification data, skipping");
      return null;
    }

    // Get the target partner's FCM token
    const tokenSnapshot = await admin
      .database()
      .ref(`couples/${coupleId}/tokens/${data.to}`)
      .once("value");

    const tokenData = tokenSnapshot.val();
    if (!tokenData || !tokenData.token) {
      console.log(`No FCM token found for ${data.to} in couple ${coupleId}`);
      return null;
    }

    const fcmToken = tokenData.token;

    // Build the notification
    const message = {
      token: fcmToken,
      notification: {
        title: data.senderName
          ? `${data.senderName} 💕`
          : "La Distanza Non Conta",
        body: data.message,
      },
      data: {
        type: data.type || "generic",
        coupleId: coupleId,
        from: data.from || "",
      },
      webpush: {
        headers: {
          Urgency: "high",
        },
        notification: {
          icon: "./icons/icon.svg",
          badge: "./icons/icon.svg",
          vibrate: [200, 100, 200],
          tag: `notification-${data.type || "generic"}`,
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`Push sent to ${data.to} in couple ${coupleId}`);
    } catch (error) {
      console.error("Error sending push:", error);
      // If token is invalid, clean it up
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        await admin
          .database()
          .ref(`couples/${coupleId}/tokens/${data.to}`)
          .remove();
        console.log(`Removed invalid token for ${data.to}`);
      }
    }

    return null;
  });
