from pathlib import Path
import argparse
import time


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("port")
    parser.add_argument("packet", type=Path)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--chunk", type=int, default=32)
    parser.add_argument("--chunk-delay", type=float, default=0.002)
    parser.add_argument("--open-delay", type=float, default=0.25)
    args = parser.parse_args()

    try:
        import serial
    except ImportError as exc:
        raise SystemExit("pyserial is required: python -m pip install pyserial") from exc

    packet = args.packet.read_bytes()

    with serial.Serial(args.port, args.baud, timeout=1) as ser:
        time.sleep(args.open_delay)
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        sent = 0
        while sent < len(packet):
            chunk = packet[sent:sent + args.chunk]
            ser.write(chunk)
            ser.flush()
            sent += len(chunk)
            time.sleep(args.chunk_delay)

    print(
        "SEND_LOADER_PACKET_PASS "
        f"port={args.port} baud={args.baud} bytes={len(packet)}"
    )


if __name__ == "__main__":
    main()
