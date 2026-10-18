'use strict';

// Service worker pembunuh cache lama (Cache Killer)
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // 1. Hapus semua cache storage lama yang tersimpan di HP
      try {
        const cacheKeys = await caches.keys();
        await Promise.all(cacheKeys.map((key) => caches.delete(key)));
      } catch (e) {
        console.warn('Failed to clear caches:', e);
      }

      // 2. Unregister service worker ini selamanya
      try {
        await self.registration.unregister();
      } catch (e) {
        console.warn('Failed to unregister:', e);
      }

      // 3. Paksa reload semua tab browser yang sedang terbuka
      try {
        const clients = await self.clients.matchAll({ type: 'window' });
        for (const client of clients) {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        }
      } catch (e) {
        console.warn('Failed to navigate clients:', e);
      }
    })()
  );
});
