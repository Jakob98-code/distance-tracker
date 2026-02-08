# Distance Doesn't Matter - Real-Time Web App 🫶

A Progressive Web App (PWA) for real-time location sharing between couples in long-distance relationships.

## Features

- 📍 **Real-time location sharing** - Both partners can share their location
- 🗺️ **Interactive map** - See both locations on a beautiful map with a connecting line
- 📱 **PWA installable** - Works like a native app on phones
- 🔄 **Auto-tracking mode** - Continuous location updates
- 🌐 **Works offline** - Cached for offline access
- 🔒 **Privacy focused** - You control when to share your location

## Quick Start

### 1. Set Up Firebase (Free)

This app uses Firebase Realtime Database to sync locations between devices. Here's how to set it up:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** (or use an existing one)
3. Name your project (e.g., "distance-tracker")
4. Disable Google Analytics (optional) and click **Create**

### 2. Create Realtime Database

1. In your Firebase project, go to **Build → Realtime Database**
2. Click **"Create Database"**
3. Choose a location close to you (e.g., Europe)
4. Start in **"Test mode"** (we'll secure it later)
5. Click **Enable**

### 3. Get Your Firebase Config

1. Go to **Project Settings** (gear icon)
2. Scroll down to **"Your apps"**
3. Click the **web icon** (`</>`) to add a web app
4. Register with a nickname (e.g., "distance-web")
5. Copy the `firebaseConfig` object - you'll need it!

It looks like this:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "your-project.firebaseapp.com",
  databaseURL: "https://your-project-default-rtdb.firebaseio.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123"
};
```

### 4. Secure Your Database (Important!)

Go to **Realtime Database → Rules** and update to:

```json
{
  "rules": {
    "couples": {
      "$coupleId": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

This allows read/write access only within couple folders. For more security, you can add authentication later.

### 5. Run the App Locally

```bash
cd webapp

# Option 1: Python (built-in)
python -m http.server 8000

# Option 2: Node.js
npx serve .

# Option 3: PHP
php -S localhost:8000
```

Then open http://localhost:8000 in your browser.

### 6. Configure the App

1. Open the app in your browser
2. Paste your Firebase config JSON
3. Enter your names
4. Choose a unique **Couple ID** (e.g., "jakob-emma-2025")
5. Select who you are (Person 1 or Person 2)
6. Click **Save & Start Tracking**

### 7. Share with Your Partner

1. **Share the Couple ID** with your partner
2. They open the same app URL
3. They enter the **same Firebase config** and **same Couple ID**
4. They select **Person 2** (the other option)
5. Now you're connected! 🎉

## Deployment Options

### Option A: GitHub Pages (Free)

1. Push the `webapp` folder to a GitHub repo
2. Go to **Settings → Pages**
3. Set source to your main branch
4. Your app is live at `https://username.github.io/repo-name/`

### Option B: Netlify (Free)

1. Drag the `webapp` folder to [Netlify Drop](https://app.netlify.com/drop)
2. Get an instant URL
3. Optionally connect to Git for auto-deploy

### Option C: Vercel (Free)

```bash
npx vercel webapp
```

### Option D: Firebase Hosting (Free)

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

## Installing on Your Phone

### Android
1. Open the app in Chrome
2. Tap the **⋮** menu → **"Add to Home screen"**
3. Or wait for the install prompt to appear

### iPhone
1. Open the app in Safari
2. Tap the **Share** button → **"Add to Home Screen"**

## How It Works

```
┌─────────────┐                    ┌─────────────┐
│   Jakob's   │                    │   Emma's    │
│    Phone    │                    │    Phone    │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │  📍 Location Update              │
       ▼                                  ▼
┌─────────────────────────────────────────────────┐
│              Firebase Realtime DB                │
│  couples/jakob-emma-2025/locations/             │
│    ├── person1: {lat, lon, timestamp, city}     │
│    └── person2: {lat, lon, timestamp, city}     │
└─────────────────────────────────────────────────┘
       │                                  │
       │  ⚡ Real-time sync               │
       ▼                                  ▼
   Both see updated                  Both see updated
   distance & map!                   distance & map!
```

## Privacy & Battery Tips

- **Manual updates**: Click "Update My Location" only when you want to share
- **Auto-tracking**: Uses battery, but gives real-time updates
- **City-level only**: The app only shows the city name, not exact address
- **You control it**: Location is only shared when the app is open (unless auto-tracking)

## Customization

### Change relationship dates

Edit `app.js`:
```javascript
this.relationshipStart = new Date('2025-02-28');
this.nextMeetDate = new Date('2026-02-27');
```

### Add more features

Ideas for extending:
- Add authentication (Firebase Auth)
- Push notifications when partner updates location
- Travel history log
- Shared notes/messages
- Photo sharing
- Custom map styles

## Troubleshooting

### "Location access denied"
- Make sure to allow location access when prompted
- Check browser settings → Site settings → Location

### "Firebase connection error"
- Double-check your Firebase config JSON
- Make sure the databaseURL is correct
- Check Firebase console for errors

### App not installing on phone
- Make sure you're using HTTPS (required for PWA)
- Try clearing browser cache
- Check the manifest.json is loading correctly

## Tech Stack

- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Maps**: Leaflet.js (free, no API key needed)
- **Database**: Firebase Realtime Database
- **Geocoding**: OpenStreetMap Nominatim (free)
- **PWA**: Service Worker + Web App Manifest

---

Made with ❤️ for long-distance couples everywhere.

*Distance is just a number. What matters is that you choose each other — every day.*
