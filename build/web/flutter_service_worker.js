'use strict';

// Service worker pembunuh cache lama (Cache Destroyer)
// Memastikan semua cache lama di browser HP dan browser desktop dibersihkan total
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // 1. Hapus semua cache storage lama yang tersimpan di HP/browser
      try {
        const cacheKeys = await caches.keys();
        await Promise.all(cacheKeys.map((key) => caches.delete(key)));
      } catch (e) {
        console.warn('[SW] Gagal menghapus caches:', e);
      }

      // 2. Unregister service worker ini
      try {
        await self.registration.unregister();
      } catch (e) {
        console.warn('[SW] Gagal unregister service worker:', e);
      }

      // 3. Paksa navigasi/reload semua tab/jendela yang sedang aktif
      try {
        const clients = await self.clients.matchAll({ type: 'window' });
        for (const client of clients) {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        }
      } catch (e) {
        console.warn('[SW] Gagal navigasi clients:', e);
      }
    })()
  );
});

// Jika ada request fetch yang sempat dicegat, jangan pernah ambil dari cache!
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request, { cache: 'no-store' }).catch(() => caches.match(event.request))
  );
});
