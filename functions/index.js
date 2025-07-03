// functions/index.js
const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

// Trigger when a new book request is created
exports.onBookRequestCreated = onDocumentCreated(
    "bookRequests/{requestId}",
    async (event) => {
      const snap = event.data;
      const request = snap.data();
      const requestId = event.params.requestId;

      try {
        // Get owner's FCM token and user data
        const db = getFirestore();
        const ownerDoc = await db
            .collection("users")
            .doc(request.ownerId)
            .get();

        if (!ownerDoc.exists) {
          console.log("Owner not found:", request.ownerId);
          return;
        }

        const ownerData = ownerDoc.data();
        const fcmToken = ownerData.fcmToken;

        // Create notification in Firestore
        const notification = {
          userId: request.ownerId,
          type: "book_request",
          title: "New Book Request",
          message: `${request.borrowerName} (${request.borrowerFlatNumber}) ` +
            `wants to borrow your book`,
          isRead: false,
          relatedId: requestId,
          createdAt: new Date(),
          societyId: request.societyId,
        };

        await db
            .collection("notifications")
            .add(notification);

        // Send FCM notification if token exists
        if (fcmToken) {
          const messaging = getMessaging();
          const message = {
            notification: {
              title: "New Book Request",
              body: `${request.borrowerName} wants to borrow your book`,
            },
            data: {
              requestId: requestId,
              type: "book_request",
              navigationTarget: "requests",
            },
            token: fcmToken,
          };

          await messaging.send(message);
          console.log("FCM notification sent to owner:", request.ownerId);
        }
      } catch (error) {
        console.error("Error processing book request:", error);
      }
    },
);

// Trigger when book request status is updated
exports.onBookRequestUpdated = onDocumentUpdated(
    "bookRequests/{requestId}",
    async (event) => {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const requestId = event.params.requestId;

      // Only process if status changed
      if (beforeData.status === afterData.status) {
        return;
      }

      try {
        // Get borrower's FCM token and user data
        const db = getFirestore();
        const borrowerDoc = await db
            .collection("users")
            .doc(afterData.borrowerId)
            .get();

        if (!borrowerDoc.exists) {
          console.log("Borrower not found:", afterData.borrowerId);
          return;
        }

        const borrowerData = borrowerDoc.data();
        const fcmToken = borrowerData.fcmToken;

        let notificationType; let title; let message;

        switch (afterData.status) {
          case "approved": {
            notificationType = "request_approved";
            title = "Request Approved!";
            message = "Your book request has been approved. " +
              "You can now collect the book.";

            // Set due date (7 days from approval)
            const dueDate = new Date();
            dueDate.setDate(dueDate.getDate() + 7);

            await event.data.after.ref.update({
              dueDate: dueDate,
            });
            break;
          }

          case "rejected":
            notificationType = "request_rejected";
            title = "Request Declined";
            message = "Your book request has been declined by the owner.";
            break;

          case "returned":
            notificationType = "book_returned";
            title = "Book Returned";
            message = "Thank you for returning the book on time!";
            break;

          case "overdue":
            notificationType = "overdue";
            title = "Book Overdue";
            message = "Your borrowed book is overdue. " +
              "Please return it as soon as possible.";
            break;

          default:
            return; // Don't process other status changes
        }

        // Create notification in Firestore
        const notification = {
          userId: afterData.borrowerId,
          type: notificationType,
          title: title,
          message: message,
          isRead: false,
          relatedId: requestId,
          createdAt: new Date(),
          societyId: afterData.societyId,
        };

        await db
            .collection("notifications")
            .add(notification);

        // Send FCM notification if token exists
        if (fcmToken) {
          const messaging = getMessaging();
          const fcmMessage = {
            notification: {
              title: title,
              body: message,
            },
            data: {
              requestId: requestId,
              type: notificationType,
              navigationTarget: "myLibrary",
            },
            token: fcmToken,
          };

          await messaging.send(fcmMessage);
          console.log("FCM notification sent to borrower:",
              afterData.borrowerId);
        }
      } catch (error) {
        console.error("Error processing request status update:", error);
      }
    },
);

// Daily function to check for overdue books
exports.checkOverdueBooks = onSchedule(
    {
      schedule: "0 9 * * *", // Daily at 9 AM
      timeZone: "Asia/Kolkata",
    },
    async (event) => {
      const today = new Date();
      today.setHours(0, 0, 0, 0); // Start of today

      try {
        // Find all approved requests where due date has passed
        const db = getFirestore();
        const overdueQuery = await db
            .collection("bookRequests")
            .where("status", "==", "approved")
            .where("dueDate", "<=", today)
            .get();

        const batch = db.batch();
        const notifications = [];

        for (const doc of overdueQuery.docs) {
          const request = doc.data();

          // Update request status to overdue
          batch.update(doc.ref, {
            status: "overdue",
          });

          // Prepare overdue notification
          notifications.push({
            userId: request.borrowerId,
            type: "overdue",
            title: "Book Overdue",
            message: `Your borrowed book is overdue. ` +
              `Please return it to ${request.ownerName} immediately.`,
            isRead: false,
            relatedId: doc.id,
            createdAt: new Date(),
            societyId: request.societyId,
          });
        }

        // Commit batch update
        await batch.commit();

        // Create notifications
        const notificationBatch = db.batch();
        notifications.forEach((notification) => {
          const ref = db.collection("notifications").doc();
          notificationBatch.set(ref, notification);
        });

        await notificationBatch.commit();

        console.log(`Processed ${overdueQuery.size} overdue books`);
      } catch (error) {
        console.error("Error checking overdue books:", error);
      }
    },
);

// Clean up old notifications (older than 30 days)
exports.cleanupOldNotifications = onSchedule(
    {
      schedule: "0 2 * * 0", // Weekly at 2 AM on Sunday
    },
    async (event) => {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      try {
        const db = getFirestore();
        const oldNotifications = await db
            .collection("notifications")
            .where("createdAt", "<=", thirtyDaysAgo)
            .get();

        const batch = db.batch();

        oldNotifications.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();

        console.log(`Deleted ${oldNotifications.size} old notifications`);
      } catch (error) {
        console.error("Error cleaning up notifications:", error);
      }
    },
);

// Send return reminders (2 days before due date)
exports.sendReturnReminders = onSchedule(
    {
      schedule: "0 10 * * *", // Daily at 10 AM
      timeZone: "Asia/Kolkata",
    },
    async (event) => {
      const twoDaysFromNow = new Date();
      twoDaysFromNow.setDate(twoDaysFromNow.getDate() + 2);
      twoDaysFromNow.setHours(23, 59, 59, 999); // End of day

      const oneDayFromNow = new Date();
      oneDayFromNow.setDate(oneDayFromNow.getDate() + 2);
      oneDayFromNow.setHours(0, 0, 0, 0); // Start of day

      try {
        // Find approved requests due in 2 days
        const db = getFirestore();
        const dueSoonQuery = await db
            .collection("bookRequests")
            .where("status", "==", "approved")
            .where("dueDate", ">=", oneDayFromNow)
            .where("dueDate", "<=", twoDaysFromNow)
            .get();

        const notifications = [];
        const fcmMessages = [];

        for (const doc of dueSoonQuery.docs) {
          const request = doc.data();

          // Get borrower's FCM token
          const borrowerDoc = await db
              .collection("users")
              .doc(request.borrowerId)
              .get();

          if (borrowerDoc.exists) {
            const borrowerData = borrowerDoc.data();

            // Create reminder notification
            notifications.push({
              userId: request.borrowerId,
              type: "return_reminder",
              title: "Return Reminder",
              message: `Don't forget to return your book to ` +
                `${request.ownerName} in 2 days.`,
              isRead: false,
              relatedId: doc.id,
              createdAt: new Date(),
              societyId: request.societyId,
            });

            // Prepare FCM message if token exists
            if (borrowerData.fcmToken) {
              fcmMessages.push({
                notification: {
                  title: "Return Reminder",
                  body: `Don't forget to return your book in 2 days`,
                },
                data: {
                  requestId: doc.id,
                  type: "return_reminder",
                  navigationTarget: "myLibrary",
                },
                token: borrowerData.fcmToken,
              });
            }
          }
        }

        // Create notifications in batch
        const batch = db.batch();
        notifications.forEach((notification) => {
          const ref = db.collection("notifications").doc();
          batch.set(ref, notification);
        });

        await batch.commit();

        // Send FCM notifications
        if (fcmMessages.length > 0) {
          const messaging = getMessaging();
          await messaging.sendEach(fcmMessages);
        }

        console.log(`Sent ${notifications.length} return reminders`);
      } catch (error) {
        console.error("Error sending return reminders:", error);
      }
    },
);
