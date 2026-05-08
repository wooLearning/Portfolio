from __future__ import annotations

import argparse
from pathlib import Path

from protocol import ensure_parent
from serial_utils import default_output_dir


def parse_args() -> argparse.Namespace:
    out_dir = default_output_dir(Path(__file__))
    parser = argparse.ArgumentParser(description="Create deterministic test images for UART transfer.")
    parser.add_argument("--out", type=Path, default=out_dir / "test_l.png")
    parser.add_argument("--width", type=int, default=64)
    parser.add_argument("--height", type=int, default=64)
    parser.add_argument("--mode", choices=["L", "RGB"], default="L")
    return parser.parse_args()


def main() -> int:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Pillow is required. Run: python -m pip install -r requirements.txt") from exc

    args = parse_args()
    if args.width <= 0 or args.height <= 0:
        raise SystemExit("--width and --height must be positive.")

    if args.mode == "L":
        payload = bytearray()
        for y in range(args.height):
            for x in range(args.width):
                payload.append((x * 3 + y * 5 + ((x ^ y) & 0x0F) * 7) & 0xFF)
        image = Image.frombytes("L", (args.width, args.height), bytes(payload))
    else:
        payload = bytearray()
        for y in range(args.height):
            for x in range(args.width):
                payload.append((x * 5 + y * 3) & 0xFF)
                payload.append((x * 2 + y * 7) & 0xFF)
                payload.append((x * 11 + y * 13) & 0xFF)
        image = Image.frombytes("RGB", (args.width, args.height), bytes(payload))

    ensure_parent(args.out)
    image.save(args.out)
    print(f"Saved {args.mode} test image: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
