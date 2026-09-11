'use strict';

const CACHE_NAME = 'caresync-v20260911_06';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        if ('caches' in self) {
          const keys = await caches.keys();
          await Promise.all(keys.map((k) => caches.delete(k)));
        }
      } catch (e) {
        console.warn('Failed to clear caches:', e);
      }
      try {
        await self.clients.claim();
      } catch (e) {
        console.warn('Failed to claim clients:', e);
      }
      try {
        await self.registration.unregister();
      } catch (e) {
        console.warn('Failed to unregister service worker:', e);
      }
    })()
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request, { cache: 'no-store' }).catch(() => fetch(event.request))
  );
});
