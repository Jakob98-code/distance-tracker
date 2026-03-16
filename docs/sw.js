// Service Worker for Distance Doesn't Matter PWA
const CACHE_NAME = 'distance-tracker-v12';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './style.css',
  './app.js',
  './manifest.json',
  './icons/icon.svg',
  'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
  'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
];

// Install event - cache assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('Caching app assets');
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  self.skipWaiting();
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  // Skip Firebase and API requests
  if (event.request.url.includes('firebase') || 
      event.request.url.includes('nominatim')) {
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).then((response) => {
        // Don't cache non-successful responses
        if (!response || response.status !== 200) {
          return response;
        }
        // Clone and cache successful responses
        const responseToCache = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        });
        return response;
      });
    })
  );
});

// Background sync for location updates (future enhancement)
self.addEventListener('sync', (event) => {
  if (event.tag === 'location-sync') {
    console.log('Background sync: location update');
  }
});

// ========== PUSH NOTIFICATIONS ==========

// Import Firebase scripts for messaging in the service worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAb94k7A825Lsc8HJYFeTvl_IrS9GAoPpQ",
  authDomain: "distance-tracker-c8bbf.firebaseapp.com",
  databaseURL: "https://distance-tracker-c8bbf-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "distance-tracker-c8bbf",
  storageBucket: "distance-tracker-c8bbf.firebasestorage.app",
  messagingSenderId: "193644544453",
  appId: "1:193644544453:web:4e02be877cf2267e6ccbac"
});

const messaging = firebase.messaging();

// Handle background push messages (when app is not in foreground)
messaging.onBackgroundMessage((payload) => {
  console.log('Background message received:', payload);
  
  const { title, body, icon } = payload.notification || {};
  
  self.registration.showNotification(title || 'La Distanza Non Conta', {
    body: body || 'Hai un nuovo messaggio 💕',
    icon: icon || './icons/icon.svg',
    badge: './icons/icon.svg',
    vibrate: [200, 100, 200],
    tag: 'distance-notification',
    data: payload.data || {}
  });
});

// Handle notification click — open the app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Focus existing window if open
      for (const client of clientList) {
        if (client.url.includes('index.html') || client.url.endsWith('/')) {
          return client.focus();
        }
      }
      // Otherwise open a new window
      return clients.openWindow('./');
    })
  );
});
