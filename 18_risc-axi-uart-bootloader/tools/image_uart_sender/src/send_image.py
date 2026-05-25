from __future__ import annotations

import argparse
import time
from pathlib import Path

from protocol import HEADER_SIZE, build_packet, chunks, load_image_frame, now_stamp, write_json
from serial_utils import default_log_dir, open_uart, prepare_uart, print_ports


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Send an image to the master FPGA over UART.")
    parser.add_argument("--list-ports", action="store_true", help="List detected COM ports and exit.")
    parser.add_argument("--port", help="TX COM port connected to the master FPGA UART.")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate.")
    parser.add_argument("--image", type=Path, help="Input image path.")
    parser.add_argument("--mode", choices=["L", "RGB"], default="RGB", help="Pixel format sent to FPGA.")
    parser.add_argument("--width", type=int, default=64, help="Image width after resize.")
    parser.add_argument("--height", type=int, default=64, help="Image height after resize.")
    parser.add_argument("--raw", action="store_true", help="Send only pixel bytes, without the IMGF header.")
    parser.add_argument("--chunk-size", type=int, default=32, help="Write chunk size in bytes.")
    parser.add_argument("--chunk-delay", type=float, default=0.002, help="Delay between chunks in seconds.")
    parser.add_argument("--header-pause", type=float, default=0.05, help="Delay after framed header before payload.")
    parser.add_argument("--no-ack", action="store_true", help="Do not wait for ACK after a framed header.")
    parser.add_argument("--settle", type=float, default=0.2, help="Delay after opening UART.")
    parser.add_argument("--timeout", type=float, default=10.0, help="Serial write timeout in seconds.")
    parser.add_argument("--log-dir", type=Path, default=default_log_dir(Path(__file__)))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.list_ports:
        print_ports()
        return 0
    if not args.port:
        raise SystemExit("--port is required unless --list-ports is used.")
    if not args.image:
        raise SystemExit("--image is required.")
    if args.width <= 0 or args.height <= 0:
        raise SystemExit("--width and --height must be positive.")
    if args.chunk_size <= 0:
        raise SystemExit("--chunk-size must be positive.")

    frame = load_image_frame(args.image, args.mode, size=(args.width, args.height))
    packet = frame.payload if args.raw else build_packet(frame)
    started = time.monotonic()

    with open_uart(args.port, args.baud, args.timeout) as ser:
        prepare_uart(ser, args.settle)
        written = 0
        if args.raw:
            for chunk in chunks(packet, args.chunk_size):
                written += ser.write(chunk)
                ser.flush()
                if args.chunk_delay > 0:
                    time.sleep(args.chunk_delay)
        else:
            written += ser.write(packet[:HEADER_SIZE])
            ser.flush()
            if not args.no_ack:
                ack = read_ack(ser, args.timeout)
                if ack != b"ACK\n":
                    raise RuntimeError(f"Expected ACK after header, got {ack!r}.")
            elif args.header_pause > 0:
                time.sleep(args.header_pause)

            for chunk in chunks(packet[HEADER_SIZE:], args.chunk_size):
                written += ser.write(chunk)
                ser.flush()
                if args.chunk_delay > 0:
                    time.sleep(args.chunk_delay)
        ser.flush()

    elapsed = time.monotonic() - started
    log = {
        "script": "send_image",
        "port": args.port,
        "baud": args.baud,
        "image": str(args.image),
        "mode": args.mode,
        "raw": args.raw,
        "width": frame.width,
        "height": frame.height,
        "channels": frame.channels,
        "payload_bytes": len(frame.payload),
        "tx_bytes": len(packet),
        "written_bytes": written,
        "header_pause_s": args.header_pause,
        "elapsed_s": elapsed,
    }
    log_path = args.log_dir / f"send_{now_stamp()}.json"
    write_json(log_path, log)

    print(f"Sent {written} bytes on {args.port} at {args.baud} baud.")
    print(f"Image: {frame.width}x{frame.height}, channels={frame.channels}, raw={args.raw}")
    print(f"Log: {log_path}")
    return 0


def read_ack(ser, timeout: float) -> bytes:
    deadline = time.monotonic() + timeout
    data = bytearray()
    while time.monotonic() < deadline:
        byte = ser.read(1)
        if not byte:
            time.sleep(0.001)
            continue
        data += byte
        if data.endswith(b"ACK\n"):
            return b"ACK\n"
        if len(data) > 16:
            del data[:-16]
    return bytes(data)


if __name__ == "__main__":
    raise SystemExit(main())
