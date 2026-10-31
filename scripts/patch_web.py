#!/usr/bin/env python3
"""
scripts/patch_web.py
Script untuk otomatis membersihkan cache lama (Cache Busting & Service Worker Killer),
sehingga perubahan di website langsung muncul di browser mobile tanpa perlu hapus cache manual.
"""

import os
import re
import time
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_DIR = os.path.join(BASE_DIR, 'web')
BUILD_WEB_DIR = os.path.join(BASE_DIR, 'build', 'web')

timestamp = int(time.time())

# 1. Patch web/index.html
web_index_path = os.path.join(WEB_DIR, 'index.html')
if os.path.exists(web_index_path):
    with open(web_index_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Update cache purge script di <head>
    new_purge_script = '''  <!-- Cache Purge: Hapus Service Worker & CacheStorage lama secara tuntas pada HP / Browser -->
  <script>
    (function() {
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function(regs) {
          for (var i = 0; i < regs.length; i++) {
            regs[i].unregister();
          }
        });
      }
      if ('caches' in window) {
        caches.keys().then(function(names) {
          for (var i = 0; i < names.length; i++) {
            caches.delete(names[i]);
          }
        });
      }
    })();
  </script>'''

    content = re.sub(
        r'<!-- Cache Purge:.*?-->\s*<script>[\s\S]*?navigator\.serviceWorker\.getRegistrations[\s\S]*?</script>',
        new_purge_script,
        content
    )

    # Update flutter_bootstrap.js loader agar selalu menggunakan query dinamis
    new_bootstrap_script = '''  <script>
    // Dynamic cache-busting loader untuk flutter_bootstrap.js
    var s = document.createElement('script');
    s.src = 'flutter_bootstrap.js?v=' + Date.now();
    s.async = true;
    document.body.appendChild(s);
  </script>'''

    content = re.sub(
        r'<script src="flutter_bootstrap\.js[^"]*"[^>]*></script>',
        new_bootstrap_script,
        content
    )

    with open(web_index_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f"[OK] Patched {web_index_path}")

# 2. Patch build/web/index.html (jika sudah di-build)
build_index_path = os.path.join(BUILD_WEB_DIR, 'index.html')
if os.path.exists(build_index_path):
    with open(build_index_path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = re.sub(
        r'<!-- Cache Purge:.*?-->\s*<script>[\s\S]*?navigator\.serviceWorker\.getRegistrations[\s\S]*?</script>',
        new_purge_script,
        content
    )

    content = re.sub(
        r'<script src="flutter_bootstrap\.js[^"]*"[^>]*></script>',
        new_bootstrap_script,
        content
    )

    with open(build_index_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f"[OK] Patched {build_index_path}")

# 3. Patch build/web/flutter_bootstrap.js (jika sudah di-build)
bootstrap_path = os.path.join(BUILD_WEB_DIR, 'flutter_bootstrap.js')
if os.path.exists(bootstrap_path):
    with open(bootstrap_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Matikan pendaftaran service worker sama sekali
    content = re.sub(
        r'serviceWorkerSettings:\s*\{[^}]*\}',
        'serviceWorkerSettings: null',
        content
    )

    # Tambahkan query timestamp ke main.dart.js agar mobile browser disk cache selalu mengambil file terbaru
    content = re.sub(
        r'"mainJsPath"\s*:\s*"main\.dart\.js(?:\?[^"]*)?"',
        f'"mainJsPath":"main.dart.js?v={timestamp}"',
        content
    )

    with open(bootstrap_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f"[OK] Patched {bootstrap_path} with serviceWorkerSettings: null & mainJsPath: main.dart.js?v={timestamp}")

# 4. Copy killer service worker ke build/web/flutter_service_worker.js
sw_source = os.path.join(WEB_DIR, 'flutter_service_worker.js')
sw_target = os.path.join(BUILD_WEB_DIR, 'flutter_service_worker.js')
if os.path.exists(sw_source) and os.path.exists(BUILD_WEB_DIR):
    with open(sw_source, 'r', encoding='utf-8') as f:
        sw_code = f.read()
    with open(sw_target, 'w', encoding='utf-8', newline='\n') as f:
        f.write(sw_code)
    print(f"[OK] Copied killer service worker to {sw_target}")

# 5. Buat build/web/vercel.json (UTF-8 murni tanpa BOM)
if os.path.exists(BUILD_WEB_DIR):
    build_vercel_path = os.path.join(BUILD_WEB_DIR, 'vercel.json')
    vercel_config = {
        "cleanUrls": True,
        "rewrites": [
            { "source": "/(.*)", "destination": "/index.html" }
        ],
        "headers": [
            {
                "source": "/(.*)",
                "headers": [
                    { "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate, max-age=0, s-maxage=0" },
                    { "key": "Pragma", "value": "no-cache" },
                    { "key": "Expires", "value": "0" }
                ]
            }
        ]
    }
    with open(build_vercel_path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(vercel_config, f, indent=2)
    print(f"[OK] Generated clean UTF-8 {build_vercel_path}")

print("[DONE] Patching completed successfully!")
