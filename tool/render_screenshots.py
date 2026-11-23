import os
import json
import math
from PIL import Image, ImageDraw, ImageFont

def render_all():
    with open('build/levels_for_screenshots.json', 'r') as f:
        data = json.load(f)

    os.makedirs('build/screenshots', exist_ok=True)
    artifact_dir = r"C:\Users\vivek.kumar2\.gemini\antigravity\brain\ebc4063f-bdca-42be-ad80-6b8ad94b6aea"
    os.makedirs(os.path.join(artifact_dir, 'screenshots'), exist_ok=True)

    # Load default or fallback font
    try:
        font_large = ImageFont.truetype("arial.ttf", 26)
        font_mid = ImageFont.truetype("arial.ttf", 16)
        font_small = ImageFont.truetype("arial.ttf", 12)
        font_tiny = ImageFont.truetype("arial.ttf", 10)
        font_bold_large = ImageFont.truetype("arialbd.ttf", 28)
        font_bold_mid = ImageFont.truetype("arialbd.ttf", 18)
        font_bold_small = ImageFont.truetype("arialbd.ttf", 13)
    except:
        font_large = font_mid = font_small = font_tiny = font_bold_large = font_bold_mid = font_bold_small = ImageFont.load_default()

    for lvl_key, lvl in data.items():
        lvl_num = int(lvl_key)
        img = render_game_screen(lvl, font_large, font_mid, font_small, font_tiny, font_bold_large, font_bold_mid, font_bold_small)
        
        out_local = f'build/screenshots/level_{lvl_num}.png'
        out_artifact = os.path.join(artifact_dir, 'screenshots', f'level_{lvl_num}.png')
        img.save(out_local, format='PNG')
        img.save(out_artifact, format='PNG')
        print(f"Rendered Level {lvl_num} screenshot: {out_local}")

    # Render Level 24 Complete Screen
    lvl24 = data['24']
    img_complete = render_completed_dialog(lvl24, font_large, font_mid, font_small, font_tiny, font_bold_large, font_bold_mid, font_bold_small)
    out_complete_local = 'build/screenshots/level_24_complete.png'
    out_complete_art = os.path.join(artifact_dir, 'screenshots', 'level_24_complete.png')
    img_complete.save(out_complete_local, format='PNG')
    img_complete.save(out_complete_art, format='PNG')
    print(f"Rendered Level 24 Complete screenshot: {out_complete_local}")

def render_game_screen(lvl, font_large, font_mid, font_small, font_tiny, font_bold_large, font_bold_mid, font_bold_small):
    W, H = 540, 1170
    img = Image.new('RGB', (W, H), '#F7F8FA')
    draw = ImageDraw.Draw(img)

    # 1. Status Bar
    draw.text((36, 18), "2:57", fill="#1E293B", font=font_bold_small)
    draw.text((430, 18), "5G  88%", fill="#64748B", font=font_small)

    # 2. Top Bar
    # Pause button (left)
    draw.ellipse([30, 60, 68, 98], outline='#CBD5E1', width=2)
    draw.line([45, 73, 45, 85], fill='#1E293B', width=3)
    draw.line([53, 73, 53, 85], fill='#1E293B', width=3)

    # Center: Level Title & Tier Badge Pill
    title_text = f"Level {lvl['levelNumber']}"
    tb_w = draw.textlength(title_text, font=font_bold_large)
    draw.text(((W - tb_w) / 2, 54), title_text, fill="#1E293B", font=font_bold_large)

    tier_text = lvl['difficulty'].upper()
    tw = draw.textlength(tier_text, font=font_bold_small)
    pill_x1 = (W - tw - 24) / 2
    pill_x2 = pill_x1 + tw + 24
    draw.rounded_rectangle([pill_x1, 92, pill_x2, 114], radius=11, fill='#EEF2F6')
    draw.text((pill_x1 + 12, 95), tier_text, fill='#64748B', font=font_bold_small)

    # Right: Timer Pill
    draw.rounded_rectangle([420, 64, 508, 98], radius=17, fill='#F1F5F9', outline='#E2E8F0', width=1)
    draw.text((436, 73), "00:02", fill='#1E293B', font=font_bold_small)

    # 3. Sub-row: Remaining & % + Progress Bar
    draw.text((36, 138), f"Remaining: {lvl['totalArrows']}", fill="#64748B", font=font_bold_small)
    draw.text((475, 138), "0%", fill="#1E293B", font=font_bold_small)
    draw.rounded_rectangle([36, 162, 504, 166], radius=2, fill='#E2E8F0')

    # 4. Lives (3 Hearts)
    for i in range(3):
        hx = 240 + i * 26
        hy = 184
        draw.polygon([(hx + 8, hy + 14), (hx, hy + 5), (hx + 4, hy), (hx + 8, hy + 3), (hx + 12, hy), (hx + 16, hy + 5)], fill='#EF4444')

    # 5. Rounded Board Card
    card_x1, card_y1, card_x2, card_y2 = 28, 220, 512, 940
    # Shadow
    for off in range(1, 8):
        draw.rounded_rectangle([card_x1 - off, card_y1 - off, card_x2 + off, card_y2 + off], radius=24, outline='#06000000')
    draw.rounded_rectangle([card_x1, card_y1, card_x2, card_y2], radius=24, fill='#FFFFFF', outline='#F1F5F9', width=1)

    # Draw Board Grid & Arrows
    b_size = lvl['boardSize']
    pad = 16
    board_x = card_x1 + pad
    board_y = card_y1 + pad
    board_w = (card_x2 - card_x1) - pad * 2
    board_h = (card_y2 - card_y1) - pad * 2
    cell_size = min(board_w, board_h) / b_size

    # Dot Grid
    for r in range(b_size + 1):
        for c in range(b_size + 1):
            px = board_x + c * cell_size
            py = board_y + r * cell_size
            draw.ellipse([px - 1, py - 1, px + 1, py + 1], fill='#E2E8F0')

    # Arrows
    stroke_w = max(3, int(cell_size * 0.22))
    head_size = max(6, int(cell_size * 0.38))

    for a in lvl['arrows']:
        pts = a['points']
        dir_name = a['direction']
        
        # Draw polyline segments
        for i in range(len(pts) - 1):
            p1 = pts[i]
            p2 = pts[i + 1]
            x1 = board_x + (p1['col'] + 0.5) * cell_size
            y1 = board_y + (p1['row'] + 0.5) * cell_size
            x2 = board_x + (p2['col'] + 0.5) * cell_size
            y2 = board_y + (p2['row'] + 0.5) * cell_size
            draw.line([x1, y1, x2, y2], fill='#1E293B', width=stroke_w)
            draw.ellipse([x1 - stroke_w / 2, y1 - stroke_w / 2, x1 + stroke_w / 2, y1 + stroke_w / 2], fill='#1E293B')

        # Draw arrowhead at head
        head_pt = pts[-1]
        hx = board_x + (head_pt['col'] + 0.5) * cell_size
        hy = board_y + (head_pt['row'] + 0.5) * cell_size

        if dir_name == 'up':
            tip = (hx, hy - head_size)
            left = (hx - head_size * 0.75, hy + head_size * 0.35)
            right = (hx + head_size * 0.75, hy + head_size * 0.35)
            notch = (hx, hy + head_size * 0.05)
        elif dir_name == 'down':
            tip = (hx, hy + head_size)
            left = (hx - head_size * 0.75, hy - head_size * 0.35)
            right = (hx + head_size * 0.75, hy - head_size * 0.35)
            notch = (hx, hy - head_size * 0.05)
        elif dir_name == 'left':
            tip = (hx - head_size, hy)
            left = (hx + head_size * 0.35, hy - head_size * 0.75)
            right = (hx + head_size * 0.35, hy + head_size * 0.75)
            notch = (hx + head_size * 0.05, hy)
        else: # right
            tip = (hx + head_size, hy)
            left = (hx - head_size * 0.35, hy - head_size * 0.75)
            right = (hx - head_size * 0.35, hy + head_size * 0.75)
            notch = (hx - head_size * 0.05, hy)

        draw.polygon([tip, left, notch, right], fill='#1E293B')

    # 6. Bottom Controls: Undo, Hint (badge 3), Restart
    btn_w, btn_h = 100, 68
    btn_y = 1010
    
    # Undo
    draw.rounded_rectangle([50, btn_y, 50 + btn_w, btn_y + btn_h], radius=18, fill='#FFFFFF', outline='#E2E8F0', width=1)
    draw.text((78, btn_y + 16), "↺", fill='#94A3B8', font=font_bold_mid)
    draw.text((80, btn_y + 40), "Undo", fill='#94A3B8', font=font_bold_small)

    # Hint
    draw.rounded_rectangle([220, btn_y, 220 + btn_w, btn_y + btn_h], radius=18, fill='#FFFFFF', outline='#E2E8F0', width=1)
    draw.text((254, btn_y + 16), "💡", fill='#F59E0B', font=font_mid)
    draw.ellipse([274, btn_y + 10, 290, btn_y + 26], fill='#F59E0B')
    draw.text((279, btn_y + 11), "3", fill='#FFFFFF', font=font_tiny)
    draw.text((253, btn_y + 40), "Hint", fill='#1E293B', font=font_bold_small)

    # Restart
    draw.rounded_rectangle([390, btn_y, 390 + btn_w, btn_y + btn_h], radius=18, fill='#FFFFFF', outline='#E2E8F0', width=1)
    draw.text((424, btn_y + 16), "🔄", fill='#1E293B', font=font_mid)
    draw.text((416, btn_y + 40), "Restart", fill='#1E293B', font=font_bold_small)

    return img

def render_completed_dialog(lvl, font_large, font_mid, font_small, font_tiny, font_bold_large, font_bold_mid, font_bold_small):
    base_img = render_game_screen(lvl, font_large, font_mid, font_small, font_tiny, font_bold_large, font_bold_mid, font_bold_small)
    # Dim overlay
    dim = Image.new('RGBA', base_img.size, (0, 0, 0, 140))
    base_img.paste(dim, (0, 0), dim)
    draw = ImageDraw.Draw(base_img)

    W, H = 540, 1170
    # Dialog Card
    dw, dh = 420, 480
    dx1 = (W - dw) / 2
    dy1 = (H - dh) / 2
    dx2 = dx1 + dw
    dy2 = dy1 + dh

    draw.rounded_rectangle([dx1, dy1, dx2, dy2], radius=28, fill='#FFFFFF')

    # 3 Golden Stars
    star_y = dy1 + 40
    for i, sx in enumerate([dx1 + 110, dx1 + 180, dx1 + 250]):
        draw.text((sx, star_y - (10 if i == 1 else 0)), "★", fill='#F59E0B', font=font_large)

    # Title
    t1 = "Level Cleared!"
    tw1 = draw.textlength(t1, font=font_bold_large)
    draw.text(((W - tw1) / 2, dy1 + 110), t1, fill='#1E293B', font=font_bold_large)

    t2 = f"Level {lvl['levelNumber']} Completed"
    tw2 = draw.textlength(t2, font=font_mid)
    draw.text(((W - tw2) / 2, dy1 + 150), t2, fill='#64748B', font=font_mid)

    # Stat Card
    sc_y = dy1 + 195
    draw.rounded_rectangle([dx1 + 24, sc_y, dx2 - 24, sc_y + 90], radius=16, fill='#F8FAFC')
    
    # Time
    draw.text((dx1 + 55, sc_y + 18), "00:42", fill='#1E293B', font=font_bold_mid)
    draw.text((dx1 + 60, sc_y + 50), "Time", fill='#64748B', font=font_small)

    # Moves
    draw.text((dx1 + 185, sc_y + 18), str(lvl['totalArrows']), fill='#1E293B', font=font_bold_mid)
    draw.text((dx1 + 185, sc_y + 50), "Moves", fill='#64748B', font=font_small)

    # Optimal
    draw.text((dx1 + 300, sc_y + 18), str(lvl['totalArrows']), fill='#1E293B', font=font_bold_mid)
    draw.text((dx1 + 295, sc_y + 50), "Optimal", fill='#64748B', font=font_small)

    # Next Level Button
    nb_y = dy1 + 315
    draw.rounded_rectangle([dx1 + 24, nb_y, dx2 - 24, nb_y + 56], radius=16, fill='#1E293B')
    btn_text = "Next Level →"
    btw = draw.textlength(btn_text, font=font_bold_mid)
    draw.text(((W - btw) / 2, nb_y + 18), btn_text, fill='#FFFFFF', font=font_bold_mid)

    # Replay & Menu Buttons
    rb_y = dy1 + 385
    draw.rounded_rectangle([dx1 + 24, rb_y, dx1 + 180, rb_y + 48], radius=14, outline='#E2E8F0', width=1)
    draw.text((dx1 + 65, rb_y + 15), "Replay", fill='#1E293B', font=font_bold_small)

    draw.rounded_rectangle([dx1 + 195, rb_y, dx2 - 24, rb_y + 48], radius=14, outline='#E2E8F0', width=1)
    draw.text((dx1 + 250, rb_y + 15), "Menu", fill='#1E293B', font=font_bold_small)

    return base_img

if __name__ == '__main__':
    render_all()
