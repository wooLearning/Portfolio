from __future__ import annotations

import json
import struct
import time
import zlib
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import BinaryIO, Iterable

MAGIC = b"IMGF"
VERSION = 1
HEADER = struct.Struct("<4sBBHHII")
HEADER_SIZE = HEADER.size
VALID_CHANNELS = {1: "L", 3: "RGB"}


@dataclass(frozen=True)
class ImageFrame:
    width: int
    height: int
    channels: int
    payload: bytes

    @property
    def payload_len(self) -> int:
        return len(self.payload)

    @property
    def crc32(self) -> int:
        return zlib.crc32(self.payload) & 0xFFFFFFFF

    @property
    def mode(self) -> str:
        return channel_to_mode(self.channels)


@dataclass(frozen=True)
class FrameHeader:
    width: int
    height: int
    channels: int
    payload_len: int
    crc32: int


@dataclass(frozen=True)
class ByteMismatch:
    byte_index: int
    pixel_index: int
    x: int
    y: int
    channel: int
    expected: int
    actual: int


@dataclass(frozen=True)
class CompareResult:
    expected_len: int
    actual_len: int
    byte_mismatches: int
    pixel_mismatches: int
    max_abs_error: int
    first_mismatches: list[ByteMismatch]

    @property
    def passed(self) -> bool:
        return (
            self.expected_len == self.actual_len
            and self.byte_mismatches == 0
            and self.pixel_mismatches == 0
        )

    def to_jsonable(self) -> dict:
        data = asdict(self)
        data["passed"] = self.passed
        return data


def channel_to_mode(channels: int) -> str:
    if channels not in VALID_CHANNELS:
        raise ValueError(f"Unsupported channel count: {channels}. Use 1 or 3.")
    return VALID_CHANNELS[channels]


def mode_to_channels(mode: str) -> int:
    normalized = mode.upper()
    if normalized == "L":
        return 1
    if normalized == "RGB":
        return 3
    raise ValueError(f"Unsupported mode: {mode}. Use L or RGB.")


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def now_stamp() -> str:
    return time.strftime("%Y%m%d_%H%M%S")


def load_image_frame(image_path: Path, mode: str, size: tuple[int, int] | None = None) -> ImageFrame:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Pillow is required. Run: python -m pip install -r requirements.txt") from exc

    normalized = mode.upper()
    channels = mode_to_channels(normalized)
    with Image.open(image_path) as image:
        converted = image.convert(normalized)
        if size is not None:
            resample = getattr(Image, "Resampling", Image).LANCZOS
            converted = converted.resize(size, resample)
        width, height = converted.size
        payload = converted.tobytes()
    return ImageFrame(width=width, height=height, channels=channels, payload=payload)


def save_image_frame(frame: ImageFrame, out_path: Path) -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Pillow is required. Run: python -m pip install -r requirements.txt") from exc

    expected_len = frame.width * frame.height * frame.channels
    if len(frame.payload) != expected_len:
        raise ValueError(f"Payload length {len(frame.payload)} does not match expected {expected_len}.")
    ensure_parent(out_path)
    image = Image.frombytes(frame.mode, (frame.width, frame.height), frame.payload)
    image.save(out_path)


def build_packet(frame: ImageFrame) -> bytes:
    header = HEADER.pack(
        MAGIC,
        VERSION,
        frame.channels,
        frame.width,
        frame.height,
        frame.payload_len,
        frame.crc32,
    )
    return header + frame.payload


def parse_header(header_bytes: bytes) -> FrameHeader:
    if len(header_bytes) != HEADER_SIZE:
        raise ValueError(f"Header length must be {HEADER_SIZE}, got {len(header_bytes)}.")
    magic, version, channels, width, height, payload_len, crc32 = HEADER.unpack(header_bytes)
    if magic != MAGIC:
        raise ValueError(f"Bad magic: {magic!r}")
    if version != VERSION:
        raise ValueError(f"Unsupported version: {version}")
    if channels not in VALID_CHANNELS:
        raise ValueError(f"Unsupported channel count: {channels}")
    expected_len = width * height * channels
    if payload_len != expected_len:
        raise ValueError(f"Header payload_len {payload_len} does not match {expected_len}.")
    return FrameHeader(width=width, height=height, channels=channels, payload_len=payload_len, crc32=crc32)


def read_exact(stream: BinaryIO, byte_count: int, timeout_s: float) -> bytes:
    deadline = time.monotonic() + timeout_s
    chunks: list[bytes] = []
    remaining = byte_count
    while remaining > 0:
        if time.monotonic() > deadline:
            got = byte_count - remaining
            raise TimeoutError(f"Timed out reading {byte_count} bytes. Received {got} bytes.")
        chunk = stream.read(remaining)
        if not chunk:
            time.sleep(0.001)
            continue
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def read_framed_image(stream: BinaryIO, timeout_s: float) -> ImageFrame:
    magic = _sync_to_magic(stream, timeout_s)
    rest = read_exact(stream, HEADER_SIZE - len(MAGIC), timeout_s)
    header = parse_header(magic + rest)
    payload = read_exact(stream, header.payload_len, timeout_s)
    crc32 = zlib.crc32(payload) & 0xFFFFFFFF
    if crc32 != header.crc32:
        raise ValueError(f"CRC mismatch: expected 0x{header.crc32:08X}, got 0x{crc32:08X}.")
    return ImageFrame(width=header.width, height=header.height, channels=header.channels, payload=payload)


def read_raw_image(stream: BinaryIO, width: int, height: int, channels: int, timeout_s: float) -> ImageFrame:
    channel_to_mode(channels)
    payload_len = width * height * channels
    payload = read_exact(stream, payload_len, timeout_s)
    return ImageFrame(width=width, height=height, channels=channels, payload=payload)


def _sync_to_magic(stream: BinaryIO, timeout_s: float) -> bytes:
    deadline = time.monotonic() + timeout_s
    window = bytearray()
    while True:
        if time.monotonic() > deadline:
            raise TimeoutError(f"Timed out waiting for magic {MAGIC!r}.")
        byte = stream.read(1)
        if not byte:
            time.sleep(0.001)
            continue
        window += byte
        if len(window) > len(MAGIC):
            del window[0 : len(window) - len(MAGIC)]
        if bytes(window) == MAGIC:
            return MAGIC


def compare_payloads(
    expected: ImageFrame,
    actual: ImageFrame,
    max_first: int = 20,
) -> CompareResult:
    if (expected.width, expected.height, expected.channels) != (
        actual.width,
        actual.height,
        actual.channels,
    ):
        raise ValueError(
            "Image shape mismatch: "
            f"expected {expected.width}x{expected.height}x{expected.channels}, "
            f"actual {actual.width}x{actual.height}x{actual.channels}."
        )

    compare_len = min(len(expected.payload), len(actual.payload))
    channels = expected.channels
    width = expected.width
    byte_mismatches = abs(len(expected.payload) - len(actual.payload))
    mismatched_pixels: set[int] = set()
    max_abs_error = 0
    first: list[ByteMismatch] = []

    for index in range(compare_len):
        exp = expected.payload[index]
        act = actual.payload[index]
        diff = abs(exp - act)
        if diff == 0:
            continue
        byte_mismatches += 1
        max_abs_error = max(max_abs_error, diff)
        pixel_index = index // channels
        mismatched_pixels.add(pixel_index)
        if len(first) < max_first:
            x = pixel_index % width
            y = pixel_index // width
            first.append(
                ByteMismatch(
                    byte_index=index,
                    pixel_index=pixel_index,
                    x=x,
                    y=y,
                    channel=index % channels,
                    expected=exp,
                    actual=act,
                )
            )

    return CompareResult(
        expected_len=len(expected.payload),
        actual_len=len(actual.payload),
        byte_mismatches=byte_mismatches,
        pixel_mismatches=len(mismatched_pixels),
        max_abs_error=max_abs_error,
        first_mismatches=first,
    )


def save_diff_image(expected: ImageFrame, actual: ImageFrame, out_path: Path) -> None:
    try:
        from PIL import Image, ImageChops
    except ImportError as exc:
        raise SystemExit("Pillow is required. Run: python -m pip install -r requirements.txt") from exc

    ensure_parent(out_path)
    exp_img = Image.frombytes(expected.mode, (expected.width, expected.height), expected.payload)
    act_img = Image.frombytes(actual.mode, (actual.width, actual.height), actual.payload)
    diff = ImageChops.difference(exp_img, act_img)
    diff.save(out_path)


def save_payload_txt(frame: ImageFrame, out_path: Path) -> None:
    ensure_parent(out_path)
    lines = [
        "# Slave FPGA received payload",
        f"# width={frame.width}",
        f"# height={frame.height}",
        f"# channels={frame.channels}",
        f"# payload_bytes={len(frame.payload)}",
    ]
    if frame.channels == 1:
        lines.append("# columns: pixel_index x y value_hex value_dec")
        for pixel_index, value in enumerate(frame.payload):
            x = pixel_index % frame.width
            y = pixel_index // frame.width
            lines.append(f"{pixel_index} {x} {y} 0x{value:02X} {value}")
    else:
        lines.append("# columns: pixel_index x y r_hex g_hex b_hex r_dec g_dec b_dec")
        for pixel_index in range(frame.width * frame.height):
            base = pixel_index * 3
            r, g, b = frame.payload[base : base + 3]
            x = pixel_index % frame.width
            y = pixel_index // frame.width
            lines.append(
                f"{pixel_index} {x} {y} "
                f"0x{r:02X} 0x{g:02X} 0x{b:02X} {r} {g} {b}"
            )
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_json(path: Path, data: dict) -> None:
    ensure_parent(path)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def chunks(data: bytes, chunk_size: int) -> Iterable[bytes]:
    for start in range(0, len(data), chunk_size):
        yield data[start : start + chunk_size]
