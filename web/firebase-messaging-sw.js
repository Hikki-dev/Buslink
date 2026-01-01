importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts(
  "https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyDlo0Mwe-N-NOLaMEDdxy_tj4TBS46_YhI",
  appId: "1:621148800955:web:3d267b90b25962c8eea69e",
  messagingSenderId: "621148800955",
  projectId: "buslink-416e1",
  authDomain: "buslink-416e1.firebaseapp.com",
  storageBucket: "buslink-416e1.firebasestorage.app",
  measurementId: "G-HW4Z2KZLG6",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload
  );
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
