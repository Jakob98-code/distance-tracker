// ========================================
// Distance Doesn't Matter - Real-Time App
// ========================================

// ========== FIREBASE AUTH SYSTEM ==========
class AuthManager {
  constructor(onAuthenticated) {
    this.onAuthenticated = onAuthenticated;
    this.user = null;
    this.auth = null;
  }

  init(firebaseConfig) {
    // Initialize Firebase if not already done
    if (!firebase.apps.length) {
      firebase.initializeApp(firebaseConfig);
    }
    this.auth = firebase.auth();
    
    // Listen for auth state changes
    this.auth.onAuthStateChanged((user) => {
      if (user) {
        this.user = user;
        this.hideAuthScreen();
        this.onAuthenticated(user);
      } else {
        this.user = null;
        this.showAuthScreen();
      }
    });

    this.setupEventListeners();
  }

  setupEventListeners() {
    const signInBtn = document.getElementById('auth-signin-btn');
    const signUpBtn = document.getElementById('auth-signup-btn');
    const passwordField = document.getElementById('auth-password');
    const signOutBtn = document.getElementById('sign-out-btn');

    if (signInBtn) {
      signInBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.signIn();
      });
    }
    
    if (signUpBtn) {
      signUpBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.signUp();
      });
    }
    
    // Allow Enter key to submit
    if (passwordField) {
      passwordField.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') this.signIn();
      });
    }

    // Sign out button
    if (signOutBtn) {
      signOutBtn.addEventListener('click', () => this.signOut());
    }
  }

  showAuthScreen() {
    document.getElementById('auth-screen').classList.remove('hidden');
    document.getElementById('pin-lock-screen').classList.add('hidden');
    document.getElementById('main-app').classList.add('hidden');
  }

  hideAuthScreen() {
    document.getElementById('auth-screen').classList.add('hidden');
  }

  showError(message) {
    const errorEl = document.getElementById('auth-error');
    errorEl.textContent = message;
    errorEl.classList.remove('hidden');
  }

  hideError() {
    document.getElementById('auth-error').classList.add('hidden');
  }

  setLoading(loading) {
    const signInBtn = document.getElementById('auth-signin-btn');
    const signUpBtn = document.getElementById('auth-signup-btn');
    
    if (loading) {
      signInBtn.disabled = true;
      signUpBtn.disabled = true;
      signInBtn.textContent = 'Please wait...';
      signUpBtn.textContent = 'Please wait...';
    } else {
      signInBtn.disabled = false;
      signUpBtn.disabled = false;
      signInBtn.textContent = 'Sign In';
      signUpBtn.textContent = 'Create Account';
    }
  }

  async signIn() {
    const email = document.getElementById('auth-email').value.trim();
    const password = document.getElementById('auth-password').value;

    if (!email || !password) {
      this.showError('Please enter email and password');
      return;
    }

    try {
      this.hideError();
      this.setLoading(true);
      await this.auth.signInWithEmailAndPassword(email, password);
    } catch (error) {
      console.error('Sign in error:', error);
      this.showError(this.getErrorMessage(error.code));
      this.setLoading(false);
    }
  }

  async signUp() {
    const email = document.getElementById('auth-email').value.trim();
    const password = document.getElementById('auth-password').value;

    console.log('Sign up attempt:', email);

    if (!email || !password) {
      this.showError('Please enter email and password');
      return;
    }

    if (password.length < 6) {
      this.showError('Password must be at least 6 characters');
      return;
    }

    try {
      this.hideError();
      this.setLoading(true);
      console.log('Creating account...');
      await this.auth.createUserWithEmailAndPassword(email, password);
      console.log('Account created successfully');
    } catch (error) {
      console.error('Sign up error:', error);
      this.showError(this.getErrorMessage(error.code));
      this.setLoading(false);
    }
  }

  async signOut() {
    try {
      await this.auth.signOut();
      // Clear local data on sign out
      localStorage.removeItem('appPinHash');
      window.location.reload();
    } catch (error) {
      console.error('Sign out error:', error);
    }
  }

  getErrorMessage(code) {
    const messages = {
      'auth/email-already-in-use': 'This email is already registered. Try signing in.',
      'auth/invalid-email': 'Please enter a valid email address.',
      'auth/user-not-found': 'No account found with this email.',
      'auth/wrong-password': 'Incorrect password. Please try again.',
      'auth/weak-password': 'Password should be at least 6 characters.',
      'auth/too-many-requests': 'Too many attempts. Please try again later.',
      'auth/invalid-credential': 'Invalid email or password.',
    };
    return messages[code] || 'An error occurred. Please try again.';
  }
}

// ========== PIN LOCK SYSTEM ==========
class PinLock {
  constructor(onUnlock) {
    this.onUnlock = onUnlock;
    this.enteredPin = '';
    this.isSettingPin = false;
    this.confirmPin = '';
    this.maxAttempts = 5;
    this.attempts = 0;
    this.lockoutUntil = null;
    
    this.init();
  }

  init() {
    // Check if locked out
    const lockout = localStorage.getItem('pinLockout');
    if (lockout && Date.now() < parseInt(lockout)) {
      this.lockoutUntil = parseInt(lockout);
    }

    // Check if PIN exists
    const hasPin = localStorage.getItem('appPinHash');
    
    if (!hasPin) {
      // First time - set up PIN
      this.isSettingPin = true;
      this.showSetupMode();
    } else if (this.lockoutUntil) {
      this.showLockout();
    }

    this.setupKeypad();
  }

  show() {
    document.getElementById('pin-lock-screen').classList.remove('hidden');
  }

  showSetupMode() {
    document.getElementById('pin-title').textContent = 'Create PIN';
    document.getElementById('pin-subtitle').textContent = 'Choose a 4-digit PIN to protect your app';
  }

  showConfirmMode() {
    document.getElementById('pin-title').textContent = 'Confirm PIN';
    document.getElementById('pin-subtitle').textContent = 'Enter the PIN again to confirm';
    this.clearDots();
  }

  showUnlockMode() {
    document.getElementById('pin-title').textContent = 'Enter PIN';
    document.getElementById('pin-subtitle').textContent = 'Enter your 4-digit PIN to unlock';
  }

  showLockout() {
    const remaining = Math.ceil((this.lockoutUntil - Date.now()) / 1000 / 60);
    document.getElementById('pin-title').textContent = '🔒 Locked';
    document.getElementById('pin-subtitle').textContent = `Too many attempts. Try again in ${remaining} minutes.`;
    document.getElementById('pin-error').classList.add('hidden');
  }

  setupKeypad() {
    document.querySelectorAll('.pin-key').forEach(key => {
      key.addEventListener('click', () => {
        const value = key.dataset.key;
        if (!value) return;
        
        // Check lockout
        if (this.lockoutUntil && Date.now() < this.lockoutUntil) {
          this.showLockout();
          return;
        } else if (this.lockoutUntil) {
          // Lockout expired
          this.lockoutUntil = null;
          localStorage.removeItem('pinLockout');
          this.attempts = 0;
          this.showUnlockMode();
        }

        if (value === 'delete') {
          this.deleteDigit();
        } else {
          this.addDigit(value);
        }
      });
    });
  }

  addDigit(digit) {
    if (this.enteredPin.length >= 4) return;
    
    this.enteredPin += digit;
    this.updateDots();
    
    if (this.enteredPin.length === 4) {
      setTimeout(() => this.handleComplete(), 200);
    }
  }

  deleteDigit() {
    this.enteredPin = this.enteredPin.slice(0, -1);
    this.updateDots();
    document.getElementById('pin-error').classList.add('hidden');
  }

  updateDots() {
    const dots = document.querySelectorAll('.pin-dot');
    dots.forEach((dot, i) => {
      dot.classList.toggle('filled', i < this.enteredPin.length);
    });
  }

  clearDots() {
    this.enteredPin = '';
    this.updateDots();
  }

  async handleComplete() {
    if (this.isSettingPin) {
      if (!this.confirmPin) {
        // First entry - save and ask for confirmation
        this.confirmPin = this.enteredPin;
        this.enteredPin = '';
        this.showConfirmMode();
      } else {
        // Confirming PIN
        if (this.enteredPin === this.confirmPin) {
          // PINs match - save it
          const hash = await this.hashPin(this.enteredPin);
          localStorage.setItem('appPinHash', hash);
          this.unlock();
        } else {
          // PINs don't match
          document.getElementById('pin-error').textContent = "PINs don't match. Try again.";
          document.getElementById('pin-error').classList.remove('hidden');
          this.confirmPin = '';
          this.enteredPin = '';
          this.updateDots();
          this.showSetupMode();
        }
      }
    } else {
      // Verifying PIN
      const storedHash = localStorage.getItem('appPinHash');
      const enteredHash = await this.hashPin(this.enteredPin);
      
      if (enteredHash === storedHash) {
        this.unlock();
      } else {
        this.attempts++;
        if (this.attempts >= this.maxAttempts) {
          // Lock out for 15 minutes
          this.lockoutUntil = Date.now() + 15 * 60 * 1000;
          localStorage.setItem('pinLockout', this.lockoutUntil.toString());
          this.showLockout();
        } else {
          document.getElementById('pin-error').textContent = `Incorrect PIN. ${this.maxAttempts - this.attempts} attempts left.`;
          document.getElementById('pin-error').classList.remove('hidden');
        }
        this.clearDots();
      }
    }
  }

  async hashPin(pin) {
    // Simple hash using Web Crypto API
    const encoder = new TextEncoder();
    const data = encoder.encode(pin + 'distance-salt-2025');
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }

  unlock() {
    document.getElementById('pin-lock-screen').classList.add('hidden');
    document.getElementById('main-app').classList.remove('hidden');
    this.onUnlock();
  }
}

// ========== MAIN APP ==========

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
    
    // Don't init automatically - wait for PIN unlock
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

// Initialize the app with Auth + PIN lock
document.addEventListener('DOMContentLoaded', () => {
  const tracker = new DistanceTracker();
  let pinLock = null;

  // Load config to get Firebase settings
  const savedConfig = localStorage.getItem('distanceTrackerConfig');
  const config = savedConfig ? JSON.parse(savedConfig) : null;

  if (config && config.firebaseConfig) {
    // We have Firebase config - use auth flow
    const authManager = new AuthManager((user) => {
      console.log('Authenticated as:', user.email);
      
      // After auth, show PIN lock
      pinLock = new PinLock(() => {
        tracker.init();
        window.app = tracker;
      });
      pinLock.show();
    });

    authManager.init(config.firebaseConfig);
  } else {
    // No config yet - skip auth, go to setup
    // Hide auth screen, show main app directly for setup
    document.getElementById('auth-screen').classList.add('hidden');
    document.getElementById('pin-lock-screen').classList.add('hidden');
    document.getElementById('main-app').classList.remove('hidden');
    tracker.init();
    window.app = tracker;
  }
});
