from PIL import Image, ImageDraw, ImageFont
import os

W, H = 700, 320
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Widget background: rounded rect with dark gradient
for y in range(H):
    t = y / H
    r = int(11 + (26 - 11) * t)
    g = int(15 + (31 - 15) * t)
    b = int(23 + (46 - 23) * t)
    draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

# Round corners mask
mask = Image.new("L", (W, H), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([(0, 0), (W - 1, H - 1)], radius=48, fill=255)
img.putalpha(mask)

# Border
draw.rounded_rectangle([(0, 0), (W - 1, H - 1)], radius=48, outline=(255, 255, 255, 50), width=2)

# Try to use a nice font
try:
    font_bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
    font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
    font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
    font_tiny = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 17)
    font_initial = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
except:
    font_bold = ImageFont.load_default()
    font_medium = font_bold
    font_small = font_bold
    font_tiny = font_bold
    font_initial = font_bold

pink = (255, 107, 157)
white = (255, 255, 255)
dim = (255, 255, 255, 120)

# Distance text
text = "847 km"
bbox = draw.textbbox((0, 0), text, font=font_bold)
tw = bbox[2] - bbox[0]
draw.text(((W - tw) / 2, 28), text, fill=white, font=font_bold)

# Initials row
cy = 110
circle_r = 28

# Draw initial circle 1 (J)
cx1 = 120
for dy in range(-circle_r, circle_r + 1):
    for dx in range(-circle_r, circle_r + 1):
        if dx * dx + dy * dy <= circle_r * circle_r:
            t = (dy + circle_r) / (2 * circle_r)
            cr = int(255 + (196 - 255) * t)
            cg = int(107 + (69 - 107) * t)
            cb = int(157 + (105 - 157) * t)
            img.putpixel((cx1 + dx, cy + dy), (cr, cg, cb, 255))

bbox = draw.textbbox((0, 0), "J", font=font_initial)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text((cx1 - tw / 2, cy - th / 2 - 4), "J", fill=white, font=font_initial)

# Draw initial circle 2 (D)
cx2 = W - 120
for dy in range(-circle_r, circle_r + 1):
    for dx in range(-circle_r, circle_r + 1):
        if dx * dx + dy * dy <= circle_r * circle_r:
            t = (dy + circle_r) / (2 * circle_r)
            cr = int(255 + (196 - 255) * t)
            cg = int(107 + (69 - 107) * t)
            cb = int(157 + (105 - 157) * t)
            img.putpixel((cx2 + dx, cy + dy), (cr, cg, cb, 255))

bbox = draw.textbbox((0, 0), "D", font=font_initial)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text((cx2 - tw / 2, cy - th / 2 - 4), "D", fill=white, font=font_initial)

# Line between circles
line_y = cy
draw.line([(cx1 + circle_r + 8, line_y), (W // 2 - 20, line_y)], fill=(255, 107, 157, 100), width=3)
draw.line([(W // 2 + 20, line_y), (cx2 - circle_r - 8, line_y)], fill=(255, 107, 157, 100), width=3)

# Heart emoji in center
heart = "\u2764"
bbox = draw.textbbox((0, 0), heart, font=font_medium)
tw = bbox[2] - bbox[0]
draw.text(((W - tw) / 2, cy - 16), heart, fill=pink, font=font_medium)

# Countdown
countdown = "Ci vediamo tra 12g"
bbox = draw.textbbox((0, 0), countdown, font=font_small)
tw = bbox[2] - bbox[0]
draw.text(((W - tw) / 2, 170), countdown, fill=pink, font=font_small)

# Last update
updated = "Agg. 14:38"
bbox = draw.textbbox((0, 0), updated, font=font_tiny)
tw = bbox[2] - bbox[0]
draw.text(((W - tw) / 2, 210), updated, fill=(255, 255, 255, 120), font=font_tiny)

# Add phone frame context - dark background behind widget
phone = Image.new("RGBA", (W + 80, H + 200), (20, 20, 30, 255))
phone_draw = ImageDraw.Draw(phone)

# Title
try:
    title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 20)
except:
    title_font = ImageFont.load_default()
phone_draw.text((40, 30), "Home Screen - Widget Preview", fill=(255, 255, 255, 180), font=title_font)

# Paste widget
phone.paste(img, (40, 80), img)

# Fake status bar icons at bottom
phone_draw.text((40, H + 120), "Distanza Widget (4x2)", fill=(255, 255, 255, 80), font=font_tiny)

out_path = os.path.join(os.path.dirname(__file__), "widget_preview.png")
phone.save(out_path)
print(f"Saved to {out_path}")
