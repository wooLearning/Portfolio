from pathlib import Path
import argparse
import struct


def parse_int(text: str) -> int:
    return int(text, 0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("payload", type=Path)
    parser.add_argument("packet_bin", type=Path)
    parser.add_argument("packet_hex", type=Path)
    parser.add_argument("--load-addr", type=parse_int, required=True)
    parser.add_argument("--entry", type=parse_int, required=True)
    args = parser.parse_args()

    payload = args.payload.read_bytes()
    if len(payload) % 4:
        payload += bytes(4 - (len(payload) % 4))

    checksum = sum(payload) & 0xFFFFFFFF
    header = b"RAXI" + struct.pack(
        "<IIII",
        args.load_addr & 0xFFFFFFFF,
        len(payload) & 0xFFFFFFFF,
        args.entry & 0xFFFFFFFF,
        checksum,
    )
    packet = header + payload

    args.packet_bin.parent.mkdir(parents=True, exist_ok=True)
    args.packet_hex.parent.mkdir(parents=True, exist_ok=True)
    args.packet_bin.write_bytes(packet)
    args.packet_hex.write_text(
        "".join(f"{byte:02x}\n" for byte in packet),
        encoding="ascii",
    )

    print(
        "LOADER_PACKET_PASS "
        f"payload_bytes={len(payload)} packet_bytes={len(packet)} "
        f"load_addr=0x{args.load_addr:08x} entry=0x{args.entry:08x} "
        f"checksum=0x{checksum:08x}"
    )


if __name__ == "__main__":
    main()
