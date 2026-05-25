from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from protocol import now_stamp
from serial_utils import default_output_dir, print_ports


def ask(prompt: str, default: str | None = None) -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    if value:
        return value
    if default is not None:
        return default
    return ask(prompt, default)


def ask_bool(prompt: str, default: bool) -> bool:
    marker = "Y/n" if default else "y/N"
    value = input(f"{prompt} [{marker}]: ").strip().lower()
    if not value:
        return default
    return value in {"y", "yes", "1", "true"}


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    out_dir = default_output_dir(Path(__file__))
    print("Detected COM ports:")
    print_ports()
    print()

    tx_port = ask("TX COM port connected to master FPGA UART RX", "COM4")
    rx_port = ask("RX COM port connected to slave FPGA UART TX", "COM7")
    baud = ask("Baud rate", "115200")
    mode = ask("Pixel mode (L or RGB)", "RGB").upper()
    width = ask("Resize width", "64")
    height = ask("Resize height", "64")
    raw = ask_bool("Use raw pixel-only mode", True)
    image = ask("Input image path", str(root / "image" / "rainbow64x64_rgb888.png"))
    out = ask("Received output image path", str(out_dir / f"received_{now_stamp()}.png"))

    cmd = [
        sys.executable,
        str(Path(__file__).with_name("transfer_compare.py")),
        "--tx-port",
        tx_port,
        "--rx-port",
        rx_port,
        "--baud",
        baud,
        "--image",
        image,
        "--mode",
        mode,
        "--width",
        width,
        "--height",
        height,
        "--out",
        out,
    ]
    if raw:
        cmd.append("--raw")

    print()
    print("Running:")
    print(" ".join(cmd))
    print()
    return subprocess.call(cmd, cwd=root)


if __name__ == "__main__":
    raise SystemExit(main())
