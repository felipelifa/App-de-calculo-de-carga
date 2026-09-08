from PIL import Image, ImageDraw
import os

def create_icon(size, output_path, is_maskable=False):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    margin = int(size * 0.1) if is_maskable else int(size * 0.05)
    radius = int(size * 0.18)
    
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=(204, 255, 0, 255)
    )
    
    cx, cy = size // 2, size // 2
    s = size / 24
    
    bar_thickness = int(2.0 * s)
    weight_width = int(3.0 * s)
    weight_height = int(8.0 * s)
    
    bar_left = cx - int(5.5 * s)
    bar_right = cx + int(5.5 * s)
    bar_top = cy - bar_thickness // 2
    bar_bottom = cy + bar_thickness // 2
    
    draw.rectangle([bar_left, bar_top, bar_right, bar_bottom], fill=(0, 0, 0))
    
    left_weight_x = cx - int(8.5 * s)
    draw.rectangle([
        left_weight_x, cy - weight_height // 2,
        left_weight_x + weight_width, cy + weight_height // 2
    ], fill=(0, 0, 0))
    
    left_weight_x2 = cx - int(11.0 * s)
    draw.rectangle([
        left_weight_x2, cy - int(6.0 * s),
        left_weight_x2 + int(2.0 * s), cy + int(6.0 * s)
    ], fill=(0, 0, 0))
    
    right_weight_x = cx + int(5.5 * s)
    draw.rectangle([
        right_weight_x, cy - weight_height // 2,
        right_weight_x + weight_width, cy + weight_height // 2
    ], fill=(0, 0, 0))
    
    right_weight_x2 = cx + int(9.0 * s)
    draw.rectangle([
        right_weight_x2, cy - int(6.0 * s),
        right_weight_x2 + int(2.0 * s), cy + int(6.0 * s)
    ], fill=(0, 0, 0))
    
    img.save(output_path, 'PNG')
    print(f"Created: {output_path} ({size}x{size})")

base_dir = os.path.dirname(os.path.abspath(__file__))

web_icons = os.path.join(base_dir, 'web', 'icons')
os.makedirs(web_icons, exist_ok=True)

create_icon(192, os.path.join(web_icons, 'Icon-192.png'))
create_icon(512, os.path.join(web_icons, 'Icon-512.png'))
create_icon(192, os.path.join(web_icons, 'Icon-maskable-192.png'), is_maskable=True)
create_icon(512, os.path.join(web_icons, 'Icon-maskable-512.png'), is_maskable=True)

create_icon(32, os.path.join(base_dir, 'web', 'favicon.png'))

android_res = os.path.join(base_dir, 'android', 'app', 'src', 'main', 'res')
mipmap_sizes = {
    'mipmap-hdpi': 72,
    'mipmap-mdpi': 48,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in mipmap_sizes.items():
    path = os.path.join(android_res, folder)
    os.makedirs(path, exist_ok=True)
    create_icon(size, os.path.join(path, 'ic_launcher.png'))

print("\nAll icons generated!")
