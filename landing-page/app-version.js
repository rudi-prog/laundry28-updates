/**
 * Laundry28 - Dynamic Version Checker
 * Fetches latest version info from Supabase and updates download links on the landing page.
 * Falls back to hardcoded URL if fetch fails.
 */

(function () {
    'use strict';

    // ============================================
    // Configuration
    // ============================================

    // Production Supabase (landing page is public-facing)
    const SUPABASE_URL = 'https://iqdmlsslzhlchbuiklwf.supabase.co';
    const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxZG1sc3NsemhsY2hidWlrbHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxNjM3NzIsImV4cCI6MjA4OTczOTc3Mn0.YPw0Zqgrtw9dYu5FCBXF67C5kOOfGzARzxcprlyMcp0';

    // Fallback URL (used if fetch fails)
    const FALLBACK_VERSION = '1.0.1';
    const FALLBACK_DOWNLOAD_URL =
        'https://github.com/rudi-prog/laundry28-updates/releases/download/v1.0.1/app-release.apk';

    // ============================================
    // Supabase CDN (loaded dynamically)
    // ============================================

    function loadSupabaseScript() {
        return new Promise(function (resolve, reject) {
            if (typeof window.supabase !== 'undefined') {
                resolve();
                return;
            }

            var script = document.createElement('script');
            script.src =
                'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
            script.onload = resolve;
            script.onerror = function () {
                reject(new Error('Failed to load Supabase library'));
            };
            document.head.appendChild(script);
        });
    }

    // ============================================
    // Fetch version info from Supabase
    // ============================================

    function fetchVersionInfo() {
        return loadSupabaseScript().then(function () {
            var client = window.supabase.createClient(
                SUPABASE_URL,
                SUPABASE_KEY
            );

            return client.rpc('get_app_version_info').then(function (result) {
                if (result.error) {
                    throw new Error(
                        'RPC error: ' + (result.error.message || 'Unknown error')
                    );
                }

                // Handle both single object and array responses
                var data = result.data;
                if (Array.isArray(data) && data.length > 0) {
                    data = data[0];
                }

                if (!data || !data.current || !data.download_url) {
                    throw new Error('Invalid response from Supabase');
                }

                return {
                    version: data.current,
                    downloadUrl: data.download_url,
                    changelog: data.changelog || '',
                    minSupported: data.min_supported || ''
                };
            });
        });
    }

    // ============================================
    // Update DOM elements
    // ============================================

    function updateDownloadLinks(versionInfo) {
        var downloadLinks = document.querySelectorAll('a[data-download="true"]');
        var downloadCount = 0;

        downloadLinks.forEach(function (link) {
            link.setAttribute('href', versionInfo.downloadUrl);
            downloadCount++;
        });

        console.log(
            '[Laundry28] Updated ' +
                downloadCount +
                ' download link(s) to version ' +
                versionInfo.version
        );
    }

    function updateVersionBadge(versionInfo) {
        var badge = document.querySelector('[data-version-badge]');
        if (badge) {
            badge.textContent = 'v' + versionInfo.version;
        }
    }

    // ============================================
    // Fallback handler
    // ============================================

    function applyFallback() {
        var downloadLinks = document.querySelectorAll('a[data-download="true"]');

        downloadLinks.forEach(function (link) {
            link.setAttribute('href', FALLBACK_DOWNLOAD_URL);
        });

        console.log(
            '[Laundry28] Using fallback download URL (version ' +
                FALLBACK_VERSION +
                ')'
        );
    }

    // ============================================
    // Main initialization
    // ============================================

    function init() {
        fetchVersionInfo()
            .then(function (versionInfo) {
                updateDownloadLinks(versionInfo);
                updateVersionBadge(versionInfo);
            })
            .catch(function (error) {
                console.warn(
                    '[Laundry28] Version fetch failed, using fallback:',
                    error.message
                );
                applyFallback();
            });
    }

    // Run after DOM is ready
    if (
        document.readyState === 'loading'
    ) {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
