'use strict';

const BUILD_VERSION = '20260911_09';

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
        console.warn('[CareSync SW] Cache cleanup error:', e);
      }
      try {
        await self.clients.claim();
      } catch (e) {
        console.warn('[CareSync SW] Clients claim error:', e);
      }
      try {
        const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
        for (const client of clients) {
          client.postMessage({ type: 'SW_ACTIVATED', version: BUILD_VERSION });
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        }
      } catch (e) {
        console.warn('[CareSync SW] Client reload error:', e);
      }
    })()
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  // Always fetch fresh from network for documents, scripts, and API calls to prevent stale UI
  if (event.request.mode === 'navigate' ||
      event.request.destination === 'document' ||
      event.request.destination === 'script' ||
      event.request.url.endsWith('.html') ||
      event.request.url.endsWith('.js') ||
      event.request.url.endsWith('.json') ||
      event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request, { cache: 'no-store' }).catch(() => fetch(event.request))
    );
    return;
  }
  
  event.respondWith(
    fetch(event.request).catch(() => fetch(event.request))
  );
});


