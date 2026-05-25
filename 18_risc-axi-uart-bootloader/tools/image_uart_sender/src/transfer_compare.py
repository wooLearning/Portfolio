from __future__ import annotations

import argparse
import queue
import threading
import time
from pathlib import Path
from typing import Any

from protocol import (
    HEADER_SIZE,
    ImageFrame,
    build_packet,
    chunks,
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
    parser = argparse.ArgumentParser(
        description="Send an image to master FPGA and receive/compare it from slave FPGA."
    )
    parser.add_argument("--list-ports", action="store_true", help="List detected COM ports and exit.")
    parser.add_argument("--tx-port", help="COM port connected to master FPGA UART RX.")
    parser.add_argument("--rx-port", help="COM port connected to slave FPGA UART TX.")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate for both ports.")
    parser.add_argument("--image", type=Path, help="Input image path.")
    parser.add_argument("--mode", choices=["L", "RGB"], default="RGB", help="Pixel format.")
    parser.add_argument("--width", type=int, default=64, help="Image width after resize.")
    parser.add_argument("--height", type=int, default=64, help="Image height after resize.")
    parser.add_argument("--raw", action="store_true", help="Receive raw pixel bytes from the slave FPGA.")
    parser.add_argument("--tx-raw", action="store_true", help="Send only pixel bytes to the master FPGA.")
    parser.add_argument("--tx-only", action="store_true", help="Send to master only; do not wait for slave UART output.")
    parser.add_argument("--rx-framed", action="store_true", help="Expect an IMGF header from the slave FPGA.")
    parser.add_argument("--expect-inverted", action="store_true", help="Compare RX against bit-inverted input pixels.")
    parser.add_argument("--chunk-size", type=int, default=32, help="TX write chunk size.")
    parser.add_argument("--chunk-delay", type=float, default=0.002, help="Delay between TX chunks in seconds.")
    parser.add_argument("--no-ack", action="store_true", help="Do not wait for ACK after a framed header.")
    parser.add_argument("--rx-start-delay", type=float, default=0.2, help="Delay before TX after RX is armed.")
    parser.add_argument("--settle", type=float, default=0.2, help="Delay after opening UARTs.")
    parser.add_argument("--timeout", type=float, default=30.0, help="RX timeout and TX write timeout.")
    parser.add_argument("--out", type=Path, default=out_dir / "received_transfer.png", help="Received image path.")
    parser.add_argument("--txt-out", type=Path, help="Output text dump path for received slave payload.")
    parser.add_argument("--log-dir", type=Path, default=default_log_dir(Path(__file__)))
    return parser.parse_args()


def receive_worker(
    rx_port: str,
    baud: int,
    rx_raw: bool,
    expected_shape: tuple[int, int, int],
    timeout: float,
    settle: float,
    ready: threading.Event,
    result_queue: queue.Queue[tuple[str, Any]],
) -> None:
    try:
        with open_uart(rx_port, baud, timeout) as ser:
            prepare_uart(ser, settle)
            ready.set()
            if rx_raw:
                width, height, channels = expected_shape
                frame = read_raw_image(ser, width, height, channels, timeout)
            else:
                frame = read_framed_image(ser, timeout)
        result_queue.put(("ok", frame))
    except Exception as exc:
        result_queue.put(("error", repr(exc)))
        ready.set()


def send_packet(
    tx_port: str,
    baud: int,
    packet: bytes,
    chunk_size: int,
    chunk_delay: float,
    timeout: float,
    settle: float,
    wait_ack: bool,
) -> int:
    with open_uart(tx_port, baud, timeout) as ser:
        prepare_uart(ser, settle)
        written = 0
        if wait_ack:
            written += ser.write(packet[:HEADER_SIZE])
            ser.flush()
            ack = read_ack(ser, timeout)
            if ack != b"ACK\n":
                raise RuntimeError(f"Expected ACK after header, got {ack!r}.")
            payload = packet[HEADER_SIZE:]
        else:
            payload = packet

        for chunk in chunks(payload, chunk_size):
            written += ser.write(chunk)
            ser.flush()
            if chunk_delay > 0:
                time.sleep(chunk_delay)
        ser.flush()
    return written


def read_ack(ser: Any, timeout: float) -> bytes:
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


def invert_frame(frame: ImageFrame) -> ImageFrame:
    return ImageFrame(
        width=frame.width,
        height=frame.height,
        channels=frame.channels,
        payload=bytes((0xFF - value) for value in frame.payload),
    )


def main() -> int:
    args = parse_args()
    if args.list_ports:
        print_ports()
        return 0
    if not args.tx_port:
        raise SystemExit("--tx-port is required unless --list-ports is used.")
    if not args.tx_only and not args.rx_port:
        raise SystemExit("--rx-port is required unless --tx-only or --list-ports is used.")
    if not args.image:
        raise SystemExit("--image is required.")
    if args.width <= 0 or args.height <= 0:
        raise SystemExit("--width and --height must be positive.")
    if args.chunk_size <= 0:
        raise SystemExit("--chunk-size must be positive.")

    expected = load_image_frame(args.image, args.mode, size=(args.width, args.height))
    tx_raw = args.tx_raw
    rx_raw = args.raw or not args.rx_framed
    packet = expected.payload if tx_raw else build_packet(expected)
    wait_ack = (not tx_raw) and (not args.no_ack)
    result_queue: queue.Queue[tuple[str, Any]] = queue.Queue()
    ready = threading.Event()
    started = time.monotonic()

    rx_thread: threading.Thread | None = None
    if args.tx_only:
        print("TX-only mode: not waiting for slave UART output.", flush=True)
    else:
        rx_thread = threading.Thread(
            target=receive_worker,
            args=(
                args.rx_port,
                args.baud,
                rx_raw,
                (expected.width, expected.height, expected.channels),
                args.timeout,
                args.settle,
                ready,
                result_queue,
            ),
            daemon=True,
        )
        rx_thread.start()
        if not ready.wait(timeout=5.0):
            raise SystemExit("RX thread did not become ready within 5 seconds.")
        print(f"RX armed on {args.rx_port}.", flush=True)
        if args.rx_start_delay > 0:
            time.sleep(args.rx_start_delay)

    print(f"Sending {len(packet)} bytes on {args.tx_port}.", flush=True)
    if wait_ack:
        print("Waiting for master ACK after IMGF header.", flush=True)
    written = send_packet(
        args.tx_port,
        args.baud,
        packet,
        args.chunk_size,
        args.chunk_delay,
        args.timeout,
        args.settle,
        wait_ack,
    )

    if args.tx_only:
        elapsed = time.monotonic() - started
        log = {
            "script": "transfer_compare",
            "tx_port": args.tx_port,
            "rx_port": args.rx_port,
            "baud": args.baud,
            "image": str(args.image),
            "mode": args.mode,
            "raw": args.raw,
            "tx_raw": tx_raw,
            "rx_raw": rx_raw,
            "tx_only": True,
            "wait_ack": wait_ack,
            "expect_inverted": args.expect_inverted,
            "width": expected.width,
            "height": expected.height,
            "channels": expected.channels,
            "payload_bytes": len(expected.payload),
            "tx_bytes": len(packet),
            "written_bytes": written,
            "elapsed_s": elapsed,
        }
        log_path = args.log_dir / f"transfer_{now_stamp()}.json"
        write_json(log_path, log)
        print(f"Sent {written} bytes: {args.tx_port} -> master FPGA")
        print("TX-only: PASS. Check board LED for DMA result, expected 530D.")
        print(f"Log: {log_path}")
        return 0

    assert rx_thread is not None
    rx_thread.join(timeout=args.timeout + 2.0)
    if rx_thread.is_alive():
        raise SystemExit("RX thread did not finish before timeout.")
    status, data = result_queue.get_nowait()
    if status != "ok":
        raise SystemExit(f"RX failed: {data}")
    received: ImageFrame = data
    compare_expected = invert_frame(expected) if args.expect_inverted else expected

    save_image_frame(received, args.out)
    txt_out = args.txt_out or args.out.with_name(args.out.stem + "_rx.txt")
    save_payload_txt(received, txt_out)
    comparison = compare_payloads(compare_expected, received)
    diff_path = args.out.with_name(args.out.stem + "_diff.png")
    save_diff_image(compare_expected, received, diff_path)

    elapsed = time.monotonic() - started
    log = {
        "script": "transfer_compare",
        "tx_port": args.tx_port,
        "rx_port": args.rx_port,
        "baud": args.baud,
        "image": str(args.image),
        "mode": args.mode,
        "raw": args.raw,
        "tx_raw": tx_raw,
        "rx_raw": rx_raw,
        "tx_only": False,
        "wait_ack": wait_ack,
        "expect_inverted": args.expect_inverted,
        "width": expected.width,
        "height": expected.height,
        "channels": expected.channels,
        "payload_bytes": len(expected.payload),
        "tx_bytes": len(packet),
        "written_bytes": written,
        "out": str(args.out),
        "txt_out": str(txt_out),
        "diff_path": str(diff_path),
        "elapsed_s": elapsed,
        "comparison": comparison.to_jsonable(),
    }
    log_path = args.log_dir / f"transfer_{now_stamp()}.json"
    write_json(log_path, log)

    print(f"Sent {written} bytes: {args.tx_port} -> master FPGA")
    print(f"Received {len(received.payload)} payload bytes: slave FPGA -> {args.rx_port}")
    print(f"Saved received image: {args.out}")
    print(f"Saved RX text: {txt_out}")
    print(f"Saved diff image: {diff_path}")
    print("Compare:", "PASS" if comparison.passed else "FAIL")
    print(f"Byte mismatches: {comparison.byte_mismatches}")
    print(f"Pixel mismatches: {comparison.pixel_mismatches}")
    print(f"Max abs error: {comparison.max_abs_error}")
    if comparison.first_mismatches:
        print("First mismatches:")
        for mismatch in comparison.first_mismatches:
            print(
                f"  byte={mismatch.byte_index} pixel={mismatch.pixel_index} "
                f"(x={mismatch.x}, y={mismatch.y}, ch={mismatch.channel}) "
                f"expected={mismatch.expected} actual={mismatch.actual}"
            )
    print(f"Log: {log_path}")
    return 0 if comparison.passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
