# Image UART Sender

This folder contains the PC-side Python tool for UART image transfer experiments.

## Contents

- `src/send_image.py`: send an image payload over UART.
- `src/receive_image.py`: receive image/data back when the target flow supports it.
- `src/transfer_compare.py`: transfer and compare helper.
- `src/gui_transfer.py`: GUI wrapper.
- `src/protocol.py`: packet/protocol helpers.
- `src/serial_utils.py`: serial port utilities.
- `src/make_test_image.py`: test image generation helper.
- `images/`: sample image inputs.
- `docs/README.md`, `docs/EXECUTION_GUIDE.md`: original tool docs.

## Launchers

```bat
run_gui.bat
run_transfer.bat
```

## Position In The Whole Project

This tool is for image/data transfer over UART. The executable-code loader flow lives in `tools/flows/loader/packet_tools/` and uses `make_loader_packet.py` plus `send_loader_packet.py`.
