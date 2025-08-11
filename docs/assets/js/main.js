// Platform detection and download management
(function() {
    'use strict';

    // GitHub repository information
    const GITHUB_REPO = 'AndyGraviet/dew_app';
    const GITHUB_API = `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`;

    // Platform detection
    function detectPlatform() {
        const userAgent = navigator.userAgent.toLowerCase();
        const platform = navigator.platform.toLowerCase();
        
        if (platform.indexOf('mac') !== -1 || userAgent.indexOf('macintosh') !== -1) {
            // Detect Intel vs Apple Silicon (approximate)
            return 'macos';
        } else if (platform.indexOf('win') !== -1 || userAgent.indexOf('windows') !== -1) {
            return 'windows';
        } else if (platform.indexOf('linux') !== -1 || userAgent.indexOf('linux') !== -1) {
            return 'linux';
        }
        
        return 'unknown';
    }

    // Get architecture (best guess for macOS)
    function getArchitecture() {
        // This is a rough detection - newer Macs are likely Apple Silicon
        const userAgent = navigator.userAgent;
        if (userAgent.indexOf('Intel') !== -1) {
            return 'intel';
        }
        // Default to Apple Silicon for newer Macs
        return 'apple-silicon';
    }

    // Update platform detection display
    function updatePlatformDetection() {
        const platform = detectPlatform();
        const arch = getArchitecture();
        const detectedElement = document.getElementById('detected-platform');
        
        if (!detectedElement) return;

        let displayText = '';
        switch (platform) {
            case 'macos':
                displayText = `macOS (${arch === 'intel' ? 'Intel' : 'Apple Silicon'})`;
                break;
            case 'windows':
                displayText = 'Windows';
                break;
            case 'linux':
                displayText = 'Linux';
                break;
            default:
                displayText = 'Unknown Platform';
        }

        detectedElement.textContent = `Detected: ${displayText}`;
    }

    // Fetch latest release information
    async function fetchLatestRelease() {
        try {
            const response = await fetch(GITHUB_API);
            const data = await response.json();
            
            // Update version information
            const versionElements = document.querySelectorAll('.version-number');
            versionElements.forEach(el => {
                el.textContent = data.tag_name;
            });

            // Update download links
            updateDownloadLinks(data.assets);
            
            return data;
        } catch (error) {
            console.error('Failed to fetch release information:', error);
            // Fallback to static links if API fails
            return null;
        }
    }

    // Update download links with actual release URLs
    function updateDownloadLinks(assets) {
        const linkMap = {
            'download-macos-universal': 'dew_app-macos-universal.dmg',
            'download-windows': 'dew_app-windows-x64.zip'
        };

        Object.entries(linkMap).forEach(([elementId, fileName]) => {
            const element = document.getElementById(elementId);
            if (element) {
                const asset = assets.find(asset => asset.name === fileName);
                if (asset) {
                    element.href = asset.browser_download_url;
                    
                    // Add download count if available
                    const downloadCount = element.querySelector('.download-count');
                    if (downloadCount && asset.download_count) {
                        downloadCount.textContent = `${asset.download_count.toLocaleString()} downloads`;
                    }
                } else {
                    // Fallback to GitHub releases page
                    element.href = `https://github.com/${GITHUB_REPO}/releases/latest`;
                }
            }
        });
    }

    // Highlight recommended download based on platform
    function highlightRecommendedDownload() {
        const platform = detectPlatform();
        const arch = getArchitecture();
        
        // Remove existing primary classes
        document.querySelectorAll('.download-btn.primary').forEach(el => {
            el.classList.remove('primary');
        });

        let recommendedId = '';
        switch (platform) {
            case 'macos':
                recommendedId = 'download-macos-universal';
                break;
            case 'windows':
                recommendedId = 'download-windows';
                break;
        }

        const recommendedElement = document.getElementById(recommendedId);
        if (recommendedElement) {
            recommendedElement.classList.add('primary');
        }
    }

    // Track download analytics
    function trackDownload(platform) {
        // You can integrate with analytics services here
        console.log(`Download started for platform: ${platform}`);
        
        // Example: Google Analytics event tracking
        if (typeof gtag !== 'undefined') {
            gtag('event', 'download', {
                'event_category': 'App Download',
                'event_label': platform,
                'value': 1
            });
        }
    }

    // Add click tracking to download buttons
    function addDownloadTracking() {
        document.querySelectorAll('.download-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                const platform = this.id.replace('download-', '');
                trackDownload(platform);
            });
        });
    }

    // Smooth scrolling for anchor links
    function enableSmoothScrolling() {
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                const href = this.getAttribute('href');
                // Only handle actual anchor links
                if (href && href.startsWith('#')) {
                    e.preventDefault();
                    const target = document.querySelector(href);
                    if (target) {
                        target.scrollIntoView({
                            behavior: 'smooth',
                            block: 'start'
                        });
                    }
                }
            });
        });
    }

    // Auto-update check notification (for existing users)
    function checkForUpdates() {
        // This could check localStorage for the last known version
        // and notify users if a newer version is available
        const lastKnownVersion = localStorage.getItem('dewapp-last-version');
        
        fetchLatestRelease().then(release => {
            if (release && lastKnownVersion && release.tag_name !== lastKnownVersion) {
                showUpdateNotification(release.tag_name);
            }
            
            // Store current version
            if (release) {
                localStorage.setItem('dewapp-last-version', release.tag_name);
            }
        });
    }

    // Show update notification
    function showUpdateNotification(version) {
        const notification = document.createElement('div');
        notification.className = 'update-notification';
        notification.innerHTML = `
            <div class="update-content">
                <strong>New version available: ${version}</strong>
                <p>Download the latest version for new features and improvements.</p>
                <button onclick="this.parentElement.parentElement.remove()">Dismiss</button>
            </div>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 10 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 10000);
    }

    // Initialize everything when DOM is loaded
    document.addEventListener('DOMContentLoaded', function() {
        updatePlatformDetection();
        fetchLatestRelease().then(() => {
            highlightRecommendedDownload();
        });
        addDownloadTracking();
        enableSmoothScrolling();
        
        // Check for updates after a delay
        setTimeout(checkForUpdates, 2000);
    });

    // Export functions for global access if needed
    window.dewApp = {
        detectPlatform,
        fetchLatestRelease,
        trackDownload
    };
})();