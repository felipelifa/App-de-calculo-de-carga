import math
from PIL import Image, ImageDraw, ImageFilter

def create_anilha_icon(size=1024):
    """Create the anilha icon matching the SVG design"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Neon green background (#CCFF00)
    neon = (204, 255, 0)
    # Rounded rectangle
    margin = int(size * 0.08)
    radius = int(size * 0.25)
    
    # Draw rounded rect background
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=neon
    )
    
    # Draw the anilha (weight plate) in black
    cx, cy = size // 2, size // 2
    stroke = max(int(size * 0.08), 4)
    
    # Horizontal bars (top and bottom)
    bar_y1 = int(cy - size * 0.22)
    bar_y2 = int(cy + size * 0.22)
    x1 = int(cx - size * 0.23)
    x2 = int(cx + size * 0.23)
    draw.line([(x1, bar_y1), (x2, bar_y1)], fill=(0, 0, 0), width=stroke)
    draw.line([(x1, bar_y2), (x2, bar_y2)], fill=(0, 0, 0), width=stroke)
    
    # Vertical bars (sides)
    bar_x1 = int(cx - size * 0.38)
    bar_x2 = int(cx + size * 0.38)
    y1 = int(cy - size * 0.17)
    y2 = int(cy + size * 0.17)
    draw.line([(bar_x1, y1), (bar_x1, y2)], fill=(0, 0, 0), width=stroke)
    draw.line([(bar_x2, y1), (bar_x2, y2)], fill=(0, 0, 0), width=stroke)
    
    # Center bar (grip)
    grip_x1 = int(cx - size * 0.13)
    grip_x2 = int(cx + size * 0.13)
    draw.line([(grip_x1, cy - size * 0.17), (grip_x1, cy + size * 0.17)], fill=(0, 0, 0), width=stroke)
    draw.line([(grip_x2, cy - size * 0.17), (grip_x2, cy + size * 0.17)], fill=(0, 0, 0), width=stroke)
    
    # Outer plates
    plate_x1 = int(cx - size * 0.44)
    plate_x2 = int(cx + size * 0.44)
    draw.line([(plate_x1, y1 - int(size * 0.05)), (plate_x1, y2 + int(size * 0.05))], fill=(0, 0, 0), width=stroke)
    draw.line([(plate_x2, y1 - int(size * 0.05)), (plate_x2, y2 + int(size * 0.05))], fill=(0, 0, 0), width=stroke)
    
    return img

def generate_all():
    base = create_anilha_icon(1024)
    
    # Android mipmap sizes
    android = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, sz in android.items():
        icon = base.resize((sz, sz), Image.Resampling.LANCZOS)
        icon.save(f"android/app/src/main/res/{folder}/ic_launcher.png", 'PNG')
        print(f"  {folder}/ic_launcher.png ({sz}x{sz})")
    
    # Flutter web icons
    web = {
        'web/favicon.png': 32,
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
    }
    for path, sz in web.items():
        icon = base.resize((sz, sz), Image.Resampling.LANCZOS)
        icon.save(path, 'PNG')
        print(f"  {path} ({sz}x{sz})")
    
    # Save high-res
    base.save("assets/icon_1024.png", 'PNG')
    print("  assets/icon_1024.png (1024x1024)")
    
    # ICO for Next.js (public/favicon.ico)
    ico_sizes = [(16,16), (32,32), (48,48)]
    ico_imgs = [base.resize(s, Image.Resampling.LANCZOS) for s in ico_sizes]
    ico_imgs[0].save("../public/favicon.ico", format='ICO', sizes=ico_sizes, append_images=ico_imgs[1:])
    ico_imgs[0].save("../app/favicon.ico", format='ICO', sizes=ico_sizes, append_images=ico_imgs[1:])
    print("  public/favicon.ico + app/favicon.ico")

if __name__ == "__main__":
    generate_all()
    print("\nDone!")
