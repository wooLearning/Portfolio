"""Small SVG/PNG drawing helper for the CAN frame overview."""
from pathlib import Path
from html import escape
import math
import os
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[1]
DIAGRAMS = ROOT / "docs" / "diagrams"
FONT = Path(os.environ.get("KOREAN_FONT", "C:/Windows/Fonts/malgun.ttf"))
BOLD_FONT = Path(os.environ.get("KOREAN_BOLD_FONT", "C:/Windows/Fonts/malgunbd.ttf"))
NAVY, BLUE, TEAL = "#16324f", "#1765c1", "#008b83"
MUTED, GRID, PALE = "#576b80", "#d9e3ed", "#f3f7fb"

class Canvas:
    """Identical drawing operations produce an editable SVG and a crisp PNG."""
    def __init__(self, name, width, height, title):
        self.name, self.width, self.height = name, width, height
        self.scale = 2
        self.image = Image.new("RGB", (width*self.scale, height*self.scale), "white")
        self.draw = ImageDraw.Draw(self.image)
        self.fonts = {}
        self.svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img">',
                    f'<title>{escape(title)}</title><rect width="100%" height="100%" fill="white"/>']

    def text(self, x, y, value, size=22, color=NAVY, bold=False, center=False):
        key = (size, bold)
        if key not in self.fonts:
            self.fonts[key] = ImageFont.truetype(str(BOLD_FONT if bold else FONT), size*self.scale)
        font = self.fonts[key]
        value = str(value)
        width = self.draw.textlength(value, font=font) / self.scale
        xx = x-width/2 if center else x
        self.draw.text((xx*self.scale, y*self.scale), value, font=font, fill=color)
        anchor = "middle" if center else "start"
        self.svg.append(f'<text x="{x}" y="{y+size}" fill="{color}" font-family="Malgun Gothic, sans-serif" font-size="{size}" font-weight="{700 if bold else 400}" text-anchor="{anchor}">{escape(value)}</text>')

    def line(self, points, color=BLUE, width=2):
        self.draw.line([(x*self.scale,y*self.scale) for x,y in points],fill=color,width=max(1,int(width*self.scale)))
        self.svg.append(f'<polyline points="{" ".join(f"{x},{y}" for x,y in points)}" fill="none" stroke="{color}" stroke-width="{width}"/>')

    def rect(self, x, y, w, h, fill=PALE, stroke=GRID, radius=10):
        self.draw.rounded_rectangle((x*self.scale,y*self.scale,(x+w)*self.scale,(y+h)*self.scale),
                                   radius=radius*self.scale,fill=fill,outline=stroke,width=2*self.scale)
        self.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')

    def arrow(self, points, color=BLUE):
        self.line(points,color,3)
        (x0,y0),(x1,y1)=points[-2:]
        angle=math.atan2(y1-y0,x1-x0)
        a=(x1-12*math.cos(angle-.45),y1-12*math.sin(angle-.45))
        b=(x1-12*math.cos(angle+.45),y1-12*math.sin(angle+.45))
        self.line([a,(x1,y1),b],color,3)

    def save(self):
        (DIAGRAMS / f"{self.name}.svg").write_text("\n".join(self.svg+["</svg>"]),encoding="utf-8")
        self.image.save(DIAGRAMS / f"{self.name}.png")
