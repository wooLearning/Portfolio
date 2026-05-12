from __future__ import annotations

from pathlib import Path
import subprocess
import threading
import tkinter as tk
from tkinter import ttk


SCRIPT_DIR = Path(__file__).resolve().parent
SW_ROOT = SCRIPT_DIR.parent
BUILD_DIR = SW_ROOT / "build_scripts"


APPS = {
    "LED bringup": ("ram_board_bringup_app", "firmware_sources\\ram_board_bringup_main.c", "firmware_sources\\startup.S"),
    "LED smoke": ("ram_led_app", "firmware_sources\\ram_led_main.c", "firmware_sources\\startup.S"),
    "UART echo": ("ram_uart_echo_app", "firmware_sources\\ram_uart_echo_main.c", "firmware_sources\\startup.S"),
    "RGB DMA poll": (
        "ram_uart_dma_spi_rgb_poll_app",
        "firmware_sources\\ram_uart_dma_spi_rgb_poll_main.c",
        "firmware_sources\\startup.S",
    ),
    "RGB DMA IRQ C": (
        "ram_uart_dma_spi_rgb_irq_app",
        "firmware_sources\\ram_uart_dma_spi_rgb_irq_main.c",
        "firmware_sources\\startup_irq.S",
    ),
}


def list_ports() -> list[str]:
    try:
        import serial.tools.list_ports
    except ImportError:
        return []

    return [port.device for port in serial.tools.list_ports.comports()]


class LoaderGui(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("RISC_AXI UART Loader")
        self.geometry("760x460")

        self.port_var = tk.StringVar()
        self.app_var = tk.StringVar(value="LED bringup")
        self.status_var = tk.StringVar(value="Ready")

        self._build()
        self.refresh_ports()

    def _build(self) -> None:
        root = ttk.Frame(self, padding=12)
        root.pack(fill=tk.BOTH, expand=True)

        top = ttk.Frame(root)
        top.pack(fill=tk.X)

        ttk.Label(top, text="COM port").grid(row=0, column=0, sticky=tk.W)
        self.port_box = ttk.Combobox(top, textvariable=self.port_var, width=16)
        self.port_box.grid(row=0, column=1, padx=6, sticky=tk.W)
        ttk.Button(top, text="Refresh", command=self.refresh_ports).grid(row=0, column=2, padx=4)

        ttk.Label(top, text="App").grid(row=0, column=3, padx=(24, 0), sticky=tk.W)
        ttk.Combobox(top, textvariable=self.app_var, values=list(APPS.keys()), width=18, state="readonly").grid(
            row=0,
            column=4,
            padx=6,
            sticky=tk.W,
        )

        btns = ttk.Frame(root)
        btns.pack(fill=tk.X, pady=(12, 8))
        ttk.Button(btns, text="Build", command=self.build_app).pack(side=tk.LEFT)
        ttk.Button(btns, text="Build + Download", command=self.download_app).pack(side=tk.LEFT, padx=8)

        ttk.Label(root, textvariable=self.status_var).pack(anchor=tk.W)

        self.log = tk.Text(root, height=20, wrap=tk.WORD)
        self.log.pack(fill=tk.BOTH, expand=True, pady=(8, 0))

    def refresh_ports(self) -> None:
        ports = list_ports()
        self.port_box["values"] = ports
        if ports and not self.port_var.get():
            self.port_var.set(ports[0])
        self.status_var.set(f"Ports: {', '.join(ports) if ports else 'none found'}")

    def selected_app(self) -> tuple[str, str, str]:
        return APPS[self.app_var.get()]

    def append_log(self, text: str) -> None:
        self.log.insert(tk.END, text)
        self.log.see(tk.END)

    def run_command(self, command: list[str]) -> None:
        def worker() -> None:
            self.status_var.set("Running...")
            self.append_log("\n> " + " ".join(command) + "\n")
            proc = subprocess.run(
                command,
                cwd=SW_ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
            self.append_log(proc.stdout)
            self.status_var.set("Done" if proc.returncode == 0 else f"Failed: {proc.returncode}")

        threading.Thread(target=worker, daemon=True).start()

    def build_app(self) -> None:
        name, source, startup = self.selected_app()
        self.run_command([
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(BUILD_DIR / "build_ram_app.ps1"),
            "-Name",
            name,
            "-Source",
            source,
            "-Startup",
            startup,
        ])

    def download_app(self) -> None:
        port = self.port_var.get().strip()
        if not port:
            self.status_var.set("Select a COM port first")
            return

        name, source, startup = self.selected_app()
        self.run_command([
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(BUILD_DIR / "download_ram_app.ps1"),
            "-Port",
            port,
            "-Name",
            name,
            "-Source",
            source,
            "-Startup",
            startup,
        ])


if __name__ == "__main__":
    LoaderGui().mainloop()
