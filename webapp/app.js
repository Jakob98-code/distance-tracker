// ========================================
// Distance Doesn't Matter - Real-Time App
// ========================================

class DistanceTracker {
  constructor() {
    this.db = null;
    this.config = null;
    this.map = null;
    this.markers = {};
    this.polyline = null;
    this.watchId = null;
    this.isTracking = false;
    
    // Relationship dates (configurable)
    this.relationshipStart = new Date('2025-02-28');
    this.nextMeetDate = new Date('2026-02-27');
    
    this.init();
  }

  async init() {
    // Always setup event listeners first (for setup form to work)
    this.setupEventListeners();
    
    // Load saved config
    this.config = this.loadConfig();
    
    if (this.config && this.config.firebaseConfig) {
      this.showSetupPanel(false);
      await this.initFirebase();
      this.initMap();
      this.updateDaysCounter();
      this.listenToLocations();
    } else {
      this.showSetupPanel(true);
    }
    
    // PWA install prompt
    this.setupInstallPrompt();
    
    // Register service worker
    this.registerServiceWorker();
  }

  // ========== CONFIG & SETUP ==========
  
  loadConfig() {
    const saved = localStorage.getItem('distanceTrackerConfig');
    return saved ? JSON.parse(saved) : null;
  }

  saveConfig(config) {
    localStorage.setItem('distanceTrackerConfig', JSON.stringify(config));
    this.config = config;
  }

  showSetupPanel(show) {
    const panel = document.getElementById('setup-panel');
    if (show) {
      panel.classList.remove('hidden');
    } else {
      panel.classList.add('hidden');
      // Update names
      if (this.config) {
        document.getElementById('person1-name').textContent = this.config.person1Name || 'Person 1';
        document.getElementById('person2-name').textContent = this.config.person2Name || 'Person 2';
        document.getElementById('person1-label').textContent = this.config.person1Name || 'Person 1';
        document.getElementById('person2-label').textContent = this.config.person2Name || 'Person 2';
      }
    }
  }

  // ========== FIREBASE ==========

  async initFirebase() {
    try {
      const firebaseConfig = this.config.firebaseConfig;
      firebase.initializeApp(firebaseConfig);
      this.db = firebase.database();
      this.updateConnectionStatus('connected', 'Connected');
      console.log('Firebase initialized');
    } catch (error) {
      console.error('Firebase init error:', error);
      this.updateConnectionStatus('error', 'Connection Error');
    }
  }

  updateConnectionStatus(status, text) {
    const statusEl = document.getElementById('connection-status');
    const dotEl = statusEl.querySelector('.status-dot');
    const textEl = statusEl.querySelector('.status-text');
    
    dotEl.className = 'status-dot ' + status;
    textEl.textContent = text;
  }

  listenToLocations() {
    const coupleId = this.config.coupleId;
    
    // Listen to both locations
    this.db.ref(`couples/${coupleId}/locations`).on('value', (snapshot) => {
      const data = snapshot.val() || {};
      
      if (data.person1) {
        this.updateLocationUI('person1', data.person1);
      }
      if (data.person2) {
        this.updateLocationUI('person2', data.person2);
      }
      
      // Recalculate distance
      if (data.person1 && data.person2) {
        const distance = this.haversineKm(
          data.person1.lat, data.person1.lon,
          data.person2.lat, data.person2.lon
        );
        document.getElementById('distance').textContent = `${Math.round(distance).toLocaleString()} km`;
        
        // Update map
        this.updateMapMarkers(data.person1, data.person2);
      }
    });

    // Listen for connection state
    this.db.ref('.info/connected').on('value', (snapshot) => {
      if (snapshot.val() === true) {
        this.updateConnectionStatus('connected', 'Connected');
      } else {
        this.updateConnectionStatus('disconnected', 'Offline');
      }
    });
  }

  async updateMyLocation(lat, lon) {
    const coupleId = this.config.coupleId;
    const whoAmI = this.config.whoAmI; // 'person1' or 'person2'
    
    const locationData = {
      lat: lat,
      lon: lon,
      timestamp: Date.now(),
      updatedAt: new Date().toISOString()
    };

    // Reverse geocode to get city name
    try {
      const city = await this.reverseGeocode(lat, lon);
      locationData.city = city;
    } catch (e) {
      console.log('Geocoding failed:', e);
    }

    await this.db.ref(`couples/${coupleId}/locations/${whoAmI}`).set(locationData);
    console.log('Location updated:', locationData);
  }

  // ========== GEOLOCATION ==========

  getCurrentLocation() {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation not supported'));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            lat: position.coords.latitude,
            lon: position.coords.longitude,
            accuracy: position.coords.accuracy
          });
        },
        (error) => {
          reject(error);
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 60000
        }
      );
    });
  }

  startTracking() {
    if (this.watchId) return;
    
    this.watchId = navigator.geolocation.watchPosition(
      async (position) => {
        await this.updateMyLocation(
          position.coords.latitude,
          position.coords.longitude
        );
      },
      (error) => {
        console.error('Tracking error:', error);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 30000
      }
    );
    
    this.isTracking = true;
    document.getElementById('toggle-tracking').textContent = '⏹️ Stop Auto-Tracking';
  }

  stopTracking() {
    if (this.watchId) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }
    this.isTracking = false;
    document.getElementById('toggle-tracking').textContent = '🔄 Start Auto-Tracking';
  }

  // ========== MAP ==========

  initMap() {
    // Initialize Leaflet map
    this.map = L.map('map').setView([50, 10], 4);
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(this.map);

    // Custom icons
    this.icons = {
      person1: L.divIcon({
        className: 'custom-marker marker-person1',
        html: '📍',
        iconSize: [30, 30],
        iconAnchor: [15, 30]
      }),
      person2: L.divIcon({
        className: 'custom-marker marker-person2',
        html: '💕',
        iconSize: [30, 30],
        iconAnchor: [15, 30]
      })
    };
  }

  updateMapMarkers(loc1, loc2) {
    // Remove existing markers
    Object.values(this.markers).forEach(m => this.map.removeLayer(m));
    if (this.polyline) this.map.removeLayer(this.polyline);

    // Add new markers
    this.markers.person1 = L.marker([loc1.lat, loc1.lon], { icon: this.icons.person1 })
      .addTo(this.map)
      .bindPopup(`${this.config.person1Name}<br>${loc1.city || 'Unknown'}`);

    this.markers.person2 = L.marker([loc2.lat, loc2.lon], { icon: this.icons.person2 })
      .addTo(this.map)
      .bindPopup(`${this.config.person2Name}<br>${loc2.city || 'Unknown'}`);

    // Draw line between them
    this.polyline = L.polyline(
      [[loc1.lat, loc1.lon], [loc2.lat, loc2.lon]],
      { color: '#ff6b9d', weight: 2, dashArray: '10, 10' }
    ).addTo(this.map);

    // Fit bounds to show both markers
    const bounds = L.latLngBounds([
      [loc1.lat, loc1.lon],
      [loc2.lat, loc2.lon]
    ]);
    this.map.fitBounds(bounds, { padding: [50, 50] });
  }

  // ========== UI UPDATES ==========

  updateLocationUI(person, data) {
    const coordsEl = document.getElementById(`${person}-coords`);
    const cityEl = document.getElementById(`${person}-city`);
    const updatedEl = document.getElementById(`${person}-updated`);

    coordsEl.textContent = `${data.lat.toFixed(4)}, ${data.lon.toFixed(4)}`;
    cityEl.textContent = data.city || '';
    updatedEl.textContent = this.timeAgo(data.timestamp);
  }

  updateDaysCounter() {
    const today = new Date();
    const daysTogether = Math.floor((today - this.relationshipStart) / (1000 * 60 * 60 * 24));
    document.getElementById('days-together').textContent = daysTogether;

    if (this.nextMeetDate) {
      const daysUntil = Math.floor((this.nextMeetDate - today) / (1000 * 60 * 60 * 24));
      if (daysUntil >= 0) {
        document.getElementById('days-until-meet').textContent = `${daysUntil} days`;
      } else {
        document.getElementById('days-until-meet').textContent = 'Soon ✨';
      }
    }

    // Update every minute
    setInterval(() => this.updateDaysCounter(), 60000);
  }

  timeAgo(timestamp) {
    const seconds = Math.floor((Date.now() - timestamp) / 1000);
    
    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)} min ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)} hours ago`;
    return `${Math.floor(seconds / 86400)} days ago`;
  }

  // ========== UTILITIES ==========

  haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.asin(Math.sqrt(a));
    return R * c;
  }

  toRad(deg) {
    return deg * (Math.PI / 180);
  }

  async reverseGeocode(lat, lon) {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`
      );
      const data = await response.json();
      return data.address.city || data.address.town || data.address.village || data.address.county || 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // ========== EVENT LISTENERS ==========

  setupEventListeners() {
    // Update location button
    document.getElementById('update-location').addEventListener('click', async () => {
      const btn = document.getElementById('update-location');
      btn.disabled = true;
      btn.textContent = '📍 Getting location...';
      
      try {
        const loc = await this.getCurrentLocation();
        await this.updateMyLocation(loc.lat, loc.lon);
        btn.textContent = '✅ Location updated!';
        setTimeout(() => {
          btn.textContent = '📍 Update My Location';
          btn.disabled = false;
        }, 2000);
      } catch (error) {
        btn.textContent = '❌ Error getting location';
        console.error(error);
        setTimeout(() => {
          btn.textContent = '📍 Update My Location';
          btn.disabled = false;
        }, 2000);
      }
    });

    // Toggle tracking
    document.getElementById('toggle-tracking').addEventListener('click', () => {
      if (this.isTracking) {
        this.stopTracking();
      } else {
        this.startTracking();
      }
    });

    // Settings
    document.getElementById('show-settings').addEventListener('click', () => {
      this.showSetupPanel(true);
      // Pre-fill current values
      if (this.config) {
        document.getElementById('setup-person1').value = this.config.person1Name || '';
        document.getElementById('setup-person2').value = this.config.person2Name || '';
        document.getElementById('setup-couple-id').value = this.config.coupleId || '';
        document.getElementById('setup-who').value = this.config.whoAmI || 'person1';
        document.getElementById('firebase-config').value = JSON.stringify(this.config.firebaseConfig, null, 2);
      }
    });

    // Save setup
    document.getElementById('save-setup').addEventListener('click', async () => {
      try {
        const firebaseConfig = JSON.parse(document.getElementById('firebase-config').value);
        const config = {
          firebaseConfig,
          person1Name: document.getElementById('setup-person1').value || 'Person 1',
          person2Name: document.getElementById('setup-person2').value || 'Person 2',
          coupleId: document.getElementById('setup-couple-id').value || 'default-couple',
          whoAmI: document.getElementById('setup-who').value
        };
        
        this.saveConfig(config);
        
        // Reload to apply
        window.location.reload();
      } catch (e) {
        alert('Invalid Firebase config JSON. Please check the format.');
        console.error(e);
      }
    });
  }

  // ========== PWA ==========

  setupInstallPrompt() {
    let deferredPrompt;

    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      deferredPrompt = e;
      document.getElementById('install-prompt').classList.remove('hidden');
    });

    document.getElementById('install-btn')?.addEventListener('click', async () => {
      if (deferredPrompt) {
        deferredPrompt.prompt();
        const result = await deferredPrompt.userChoice;
        console.log('Install result:', result);
        deferredPrompt = null;
        document.getElementById('install-prompt').classList.add('hidden');
      }
    });

    document.getElementById('dismiss-install')?.addEventListener('click', () => {
      document.getElementById('install-prompt').classList.add('hidden');
    });
  }

  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        await navigator.serviceWorker.register('sw.js');
        console.log('Service Worker registered');
      } catch (e) {
        console.log('Service Worker registration failed:', e);
      }
    }
  }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', () => {
  window.app = new DistanceTracker();
});
