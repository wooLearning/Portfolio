from __future__ import annotations

import argparse
import time
from pathlib import Path

from protocol import (
    ImageFrame,
    compare_payloads,
    load_image_frame,
    now_stamp,
    read_framed_image,
    read_raw_image,
    save_diff_image,
    save_image_frame,
    save_payload_txt,
    write_json,
)
from serial_utils import default_log_dir, default_output_dir, open_uart, prepare_uart, print_ports


def parse_args() -> argparse.Namespace:
    out_dir = default_output_dir(Path(__file__))
    parser = argparse.ArgumentParser(description="Receive an image from the slave FPGA over UART.")
    parser.add_argument("--list-ports", action="store_true", help="List detected COM ports and exit.")
    parser.add_argument("--port", help="RX COM port connected to the slave FPGA UART.")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate.")
    parser.add_argument("--raw", action="store_true", help="Receive fixed-size raw pixel bytes.")
    parser.add_argument("--width", type=int, help="Raw mode image width.")
    parser.add_argument("--height", type=int, help="Raw mode image height.")
    parser.add_argument("--channels", type=int, choices=[1, 3], help="Raw mode channel count.")
    parser.add_argument("--out", type=Path, default=out_dir / "received.png", help="Output image path.")
    parser.add_argument("--txt-out", type=Path, help="Output text dump path for received slave payload.")
    parser.add_argument("--expected", type=Path, help="Original image path for comparison.")
    parser.add_argument("--mode", choices=["L", "RGB"], help="Expected image conversion mode.")
    parser.add_argument("--settle", type=float, default=0.2, help="Delay after opening UART.")
    parser.add_argument("--timeout", type=float, default=30.0, help="Serial read timeout in seconds.")
    parser.add_argument("--log-dir", type=Path, default=default_log_dir(Path(__file__)))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.list_ports:
        print_ports()
        return 0
    if not args.port:
        raise SystemExit("--port is required unless --list-ports is used.")
    if args.raw and (args.width is None or args.height is None or args.channels is None):
        raise SystemExit("--raw requires --width, --height, and --channels.")

    started = time.monotonic()
    with open_uart(args.port, args.baud, args.timeout) as ser:
        prepare_uart(ser, args.settle)
        if args.raw:
            received = read_raw_image(ser, args.width, args.height, args.channels, args.timeout)
        else:
            received = read_framed_image(ser, args.timeout)

    save_image_frame(received, args.out)
    txt_out = args.txt_out or args.out.with_name(args.out.stem + "_rx.txt")
    save_payload_txt(received, txt_out)
    comparison = None
    diff_path = None
    if args.expected:
        mode = args.mode or received.mode
        expected = load_image_frame(args.expected, mode, size=(received.width, received.height))
        comparison = compare_payloads(expected, received).to_jsonable()
        diff_path = args.out.with_name(args.out.stem + "_diff.png")
        save_diff_image(expected, received, diff_path)

    elapsed = time.monotonic() - started
    log = {
        "script": "receive_image",
        "port": args.port,
        "baud": args.baud,
        "raw": args.raw,
        "out": str(args.out),
        "txt_out": str(txt_out),
        "width": received.width,
        "height": received.height,
        "channels": received.channels,
        "payload_bytes": len(received.payload),
        "elapsed_s": elapsed,
        "comparison": comparison,
        "diff_path": str(diff_path) if diff_path else None,
    }
    log_path = args.log_dir / f"receive_{now_stamp()}.json"
    write_json(log_path, log)

    print(f"Received {len(received.payload)} payload bytes on {args.port}.")
    print(f"Saved image: {args.out}")
    print(f"Saved RX text: {txt_out}")
    if comparison:
        print("Compare:", "PASS" if comparison["passed"] else "FAIL")
        print(f"Byte mismatches: {comparison['byte_mismatches']}")
        print(f"Pixel mismatches: {comparison['pixel_mismatches']}")
        print(f"Diff image: {diff_path}")
    print(f"Log: {log_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
