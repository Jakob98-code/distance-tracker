# Distance Doesn't Matter 🫶

A sweet Python project that generates a personalized long-distance relationship dashboard.

## Features

- 🗺️ Interactive map showing both locations with a connecting line
- 📊 Stats showing distance, days together, and days until next meet
- 💌 Personalized love note
- 🎨 Beautiful dark-themed responsive HTML output

## Setup

1. **Create a virtual environment** (optional but recommended):
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   # or
   .venv\Scripts\activate     # Windows
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Customize the script**:
   Open `Distance_doesnt_matter.py` and edit the configuration section:
   - `YOU_NAME` - Your name
   - `HER_NAME` - Your partner's name
   - `YOU` - Your location (label, lat, lon)
   - `HER` - Their location (label, lat, lon)
   - `RELATIONSHIP_START` - When you started dating
   - `NEXT_MEET_DATE` - Next planned meet (or `None`)
   - `LOVE_NOTE` - A personal message

4. **Run the script**:
   ```bash
   python Distance_doesnt_matter.py
   ```

5. **Open the generated file**:
   Open `distance_doesnt_matter.html` in your browser to see the dashboard!

## Finding Coordinates

The easiest way to find coordinates:
1. Go to Google Maps
2. Right-click on the location
3. Click "What's here?"
4. Copy the latitude and longitude values

## Output

The script generates `distance_doesnt_matter.html` - a self-contained HTML file with an interactive Plotly map and your relationship stats.

---

*Distance is just a number. What matters is that you choose each other — every day.* ❤️
