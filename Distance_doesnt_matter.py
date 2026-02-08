from datetime import date, datetime
from math import radians, sin, cos, asin, sqrt
import plotly.graph_objects as go

# =========================
# EDIT THESE (ONLY THESE)
# =========================

YOU_NAME = "Jakob"
HER_NAME = "❤️"  # eller hendes navn

# Brug koordinater (mest stabilt).
# Find dem hurtigt via Google Maps: højreklik -> "What's here?" -> kopier lat/lon
YOU = {
    "label": "You (Aarhus / Denmark)",
    "lat": 56.1632,
    "lon": 10.1690,
}

HER = {
    "label": "Her (Venice / Italy)",  # ret til hendes by
    "lat": 45.4375,
    "lon": 12.335833,
}

# Sæt datoen I blev kærester / eller dagen I mødtes
RELATIONSHIP_START = date(2025, 2, 28)  # <-- ret

# Hvis du kender næste gang I ses, så sæt den her. Ellers: None
NEXT_MEET_DATE = date(2026, 2, 27)  # fx date(2026, 2, 14)

# En lille personlig tekst (du kan skrive den mere romantisk)
LOVE_NOTE = (
    "Distance is just a number.\n"
    "What matters is that I choose you — every day."
)

# =========================
# IMPLEMENTATION
# =========================

def haversine_km(lat1, lon1, lat2, lon2) -> float:
    """Great-circle distance between two points (km)."""
    R = 6371.0
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1)*cos(lat2)*sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return R * c

today = date.today()

distance_km = haversine_km(YOU["lat"], YOU["lon"], HER["lat"], HER["lon"])
days_together = (today - RELATIONSHIP_START).days

days_to_meet = None
if NEXT_MEET_DATE is not None:
    days_to_meet = (NEXT_MEET_DATE - today).days

# --- Build a small "dashboard" figure ---
# 1) Map with two points + line
map_fig = go.Figure()

map_fig.add_trace(go.Scattergeo(
    lon=[YOU["lon"], HER["lon"]],
    lat=[YOU["lat"], HER["lat"]],
    mode="lines",
    line=dict(width=2),
    hoverinfo="skip",
))

map_fig.add_trace(go.Scattergeo(
    lon=[YOU["lon"], HER["lon"]],
    lat=[YOU["lat"], HER["lat"]],
    mode="markers+text",
    text=[YOU["label"], HER["label"]],
    textposition="top center",
    marker=dict(size=10),
))

map_fig.update_layout(
    margin=dict(l=0, r=0, t=0, b=0),
    geo=dict(
        projection_type="natural earth",
        showland=True,
        landcolor="rgb(240,240,240)",
        showcountries=True,
    ),
)

# 2) A clean "numbers" strip using annotations
meet_line = ""
if days_to_meet is not None:
    if days_to_meet >= 0:
        meet_line = f"<div class='stat'><div class='k'>Days until we meet</div><div class='v'>{days_to_meet}</div></div>"
    else:
        meet_line = f"<div class='stat'><div class='k'>Days since we last planned meet date</div><div class='v'>{abs(days_to_meet)}</div></div>"

html = f"""
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Distance doesn't matter</title>
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      background: #0b0f17;
      color: #e9eef7;
      margin: 0;
      padding: 0;
    }}
    .wrap {{
      max-width: 920px;
      margin: 0 auto;
      padding: 28px 18px 40px;
    }}
    .title {{
      font-size: 32px;
      letter-spacing: 0.2px;
      margin: 6px 0 8px;
    }}
    .subtitle {{
      opacity: 0.85;
      margin: 0 0 22px;
      line-height: 1.4;
    }}
    .card {{
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.10);
      border-radius: 18px;
      padding: 18px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.25);
      margin-bottom: 14px;
    }}
    .stats {{
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
    }}
    @media (max-width: 720px) {{
      .stats {{ grid-template-columns: 1fr; }}
    }}
    .stat {{
      background: rgba(0,0,0,0.18);
      border: 1px solid rgba(255,255,255,0.10);
      border-radius: 14px;
      padding: 14px;
    }}
    .k {{
      font-size: 12px;
      opacity: 0.8;
      margin-bottom: 8px;
      text-transform: uppercase;
      letter-spacing: 0.9px;
    }}
    .v {{
      font-size: 28px;
      font-weight: 700;
    }}
    .note {{
      white-space: pre-line;
      font-size: 16px;
      line-height: 1.55;
      opacity: 0.92;
    }}
    .footer {{
      opacity: 0.65;
      font-size: 12px;
      margin-top: 12px;
    }}
    .heart {{
      display: inline-block;
      transform: translateY(1px);
    }}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="title">Distance doesn't matter <span class="heart">🫶</span></div>
    <div class="subtitle">
      A tiny dashboard for {YOU_NAME} &amp; {HER_NAME}. Generated on {today.isoformat()}.
    </div>

    <div class="card">
      <div class="stats">
        <div class="stat">
          <div class="k">Distance right now</div>
          <div class="v">{distance_km:,.0f} km</div>
        </div>
        <div class="stat">
          <div class="k">Days since we started</div>
          <div class="v">{days_together}</div>
        </div>
        {meet_line if meet_line else "<div class='stat'><div class='k'>Next meet</div><div class='v'>Soon ✨</div></div>"}
      </div>
    </div>

    <div class="card">
      {map_fig.to_html(include_plotlyjs="cdn", full_html=False)}
    </div>

    <div class="card">
      <div class="note">{LOVE_NOTE}</div>
      <div class="footer">P.S. If distance is a number, then my love is an invariant.</div>
    </div>
  </div>
</body>
</html>
"""

out_path = "distance_doesnt_matter.html"
with open(out_path, "w", encoding="utf-8") as f:
    f.write(html)

print(f"✅ Generated: {out_path}")
