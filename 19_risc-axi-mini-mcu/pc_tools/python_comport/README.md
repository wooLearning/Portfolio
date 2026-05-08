# PC UART image transfer tools

This folder contains Python-side tools for this path:

```text
PC -> UART -> master FPGA -> SPI -> slave FPGA -> UART -> PC
```

Generated logs and default output images stay under this folder:

```text
logs/
outputs/
```

## Install

```powershell
python -m pip install -r requirements.txt
```

## Find COM ports

```powershell
python .\src\send_image.py --list-ports
```

## Recommended end-to-end run

Use two USB UART ports on the same PC:

GUI:

```powershell
.\run_gui.bat
```

Terminal interactive:

```powershell
.\run_transfer.bat
```

Or run it directly with arguments:

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\outputs\test_rgb.png --mode RGB
```

For grayscale pixels:

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L
```

## Raw mode

Raw mode sends only row-major pixel bytes. Use this if the FPGA RTL does not parse a header yet.

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

In raw mode, the receiver knows the expected byte count from the input image.

## GUI

The GUI auto-detects available COM ports, but you still choose which one is the master TX port and which one is the slave RX port.

```text
Master TX Port = PC -> master FPGA UART RX
Slave RX Port  = slave FPGA UART TX -> PC
```

Run:

```powershell
.\run_gui.bat
```

The GUI shows live terminal output, communication status, PASS/FAIL, and saves:

```text
outputs/received_*.png
outputs/received_*_diff.png
outputs/received_*_rx.txt
logs/transfer_*.json
```

## Split sender and receiver

Terminal 1:

```powershell
python .\src\receive_image.py --port COM6 --baud 115200 --out .\outputs\received.png --expected .\image\gray64x64_8bit_png.png --raw --width 64 --height 64 --channels 1
```

Terminal 2:

```powershell
python .\src\send_image.py --port COM5 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

## Frame protocol

Default mode sends an 18-byte little-endian header followed by payload bytes:

```text
magic       4 bytes  "IMGF"
version     1 byte   1
channels    1 byte   1 for L, 3 for RGB
width       2 bytes  uint16
height      2 bytes  uint16
payload_len 4 bytes  uint32
crc32       4 bytes  uint32 of payload
payload     N bytes  row-major pixels
```

If the FPGA side is easier with pure pixels first, use `--raw`.

## Test image

```powershell
python .\src\make_test_image.py --out .\image\gray64x64_8bit_png.png --width 64 --height 64 --mode L
python .\src\make_test_image.py --out .\outputs\test_rgb.png --width 64 --height 64 --mode RGB
```
