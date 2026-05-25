from __future__ import annotations

import time
from pathlib import Path
from typing import Any


def require_serial():
    try:
        import serial
    except ImportError as exc:
        raise SystemExit("pyserial is required. Run: python -m pip install -r requirements.txt") from exc
    return serial


def list_ports() -> list[dict[str, Any]]:
    try:
        from serial.tools import list_ports as pyserial_list_ports
    except ImportError as exc:
        raise SystemExit("pyserial is required. Run: python -m pip install -r requirements.txt") from exc

    ports = []
    for port in pyserial_list_ports.comports():
        ports.append(
            {
                "device": port.device,
                "description": port.description,
                "hwid": port.hwid,
            }
        )
    return ports


def print_ports() -> None:
    ports = list_ports()
    if not ports:
        print("No serial ports found.")
        return
    for port in ports:
        print(f"{port['device']}: {port['description']} ({port['hwid']})")


def open_uart(port: str, baud: int, timeout_s: float):
    serial = require_serial()
    return serial.Serial(
        port=port,
        baudrate=baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=0.05,
        write_timeout=timeout_s,
    )


def prepare_uart(ser, settle_s: float) -> None:
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    if settle_s > 0:
        time.sleep(settle_s)


def default_log_dir(script_path: Path) -> Path:
    return _repo_root(script_path) / "logs" / "sender"


def default_output_dir(script_path: Path) -> Path:
    return _repo_root(script_path) / "runs" / "sender_outputs"


def _repo_root(script_path: Path) -> Path:
    for parent in script_path.resolve().parents:
        if (parent / "config").exists() and (parent / "tools").exists():
            return parent
    return script_path.resolve().parents[1]
