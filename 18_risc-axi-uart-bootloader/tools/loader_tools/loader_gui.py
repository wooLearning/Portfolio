from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import subprocess
import threading
import tkinter as tk
from tkinter import ttk


SCRIPT_DIR = Path(__file__).resolve().parent
LOADER_ROOT = SCRIPT_DIR.parent
REPO_ROOT = LOADER_ROOT.parent.parent
SW_ROOT = REPO_ROOT / "SW"
BUILD_DIR = LOADER_ROOT / "build_scripts"
FIRMWARE_DIR = SW_ROOT / "firmware_sources"


@dataclass(frozen=True)
class RamApp:
    label: str
    name: str
    source: str
    startup: str


def app_label_from_source(path: Path) -> str:
    stem = path.stem
    if stem.startswith("ram_"):
        stem = stem[4:]
    if stem.endswith("_main"):
        stem = stem[:-5]

    acronyms = {
        "apb": "APB",
        "axi": "AXI",
        "dma": "DMA",
        "gpio": "GPIO",
        "irq": "IRQ",
        "led": "LED",
        "rgb": "RGB",
        "spi": "SPI",
        "sram": "SRAM",
        "uart": "UART",
    }
    words = [acronyms.get(part, part.capitalize()) for part in stem.split("_") if part]
    if not words:
        return path.stem
    return " ".join(words)


def discover_apps() -> dict[str, RamApp]:
    apps: dict[str, RamApp] = {}
    for source_path in sorted(FIRMWARE_DIR.glob("ram_*_main.c")):
        stem = source_path.stem
        app_base = stem[:-5] if stem.endswith("_main") else stem
        app_tokens = app_base.split("ram_", 1)[-1].split("_")
        startup_name = "startup_irq.S" if "irq" in app_tokens else "startup.S"
        app = RamApp(
            label=app_label_from_source(source_path),
            name=f"{app_base}_app",
            source=str(Path("firmware_sources") / source_path.name),
            startup=str(Path("firmware_sources") / startup_name),
        )
        apps[app.label] = app
    return apps


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

        self.apps = discover_apps()
        self.port_var = tk.StringVar()
        default_app = next(iter(self.apps), "")
        self.app_var = tk.StringVar(value=default_app)
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
        self.app_box = ttk.Combobox(top, textvariable=self.app_var, values=list(self.apps.keys()), width=28, state="readonly")
        self.app_box.grid(
            row=0,
            column=4,
            padx=6,
            sticky=tk.W,
        )
        ttk.Button(top, text="Refresh Apps", command=self.refresh_apps).grid(row=0, column=5, padx=4)

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

    def refresh_apps(self) -> None:
        previous = self.app_var.get()
        self.apps = discover_apps()
        labels = list(self.apps.keys())
        self.app_box["values"] = labels
        if previous in self.apps:
            self.app_var.set(previous)
        elif labels:
            self.app_var.set(labels[0])
        else:
            self.app_var.set("")
        self.status_var.set(f"Apps: {len(labels)} found")

    def selected_app(self) -> RamApp | None:
        return self.apps.get(self.app_var.get())

    def append_log(self, text: str) -> None:
        self.log.insert(tk.END, text)
        self.log.see(tk.END)

    def run_command(self, command: list[str]) -> None:
        def worker() -> None:
            self.status_var.set("Running...")
            self.append_log("\n> " + " ".join(command) + "\n")
            proc = subprocess.run(
                command,
                cwd=REPO_ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
            self.append_log(proc.stdout)
            self.status_var.set("Done" if proc.returncode == 0 else f"Failed: {proc.returncode}")

        threading.Thread(target=worker, daemon=True).start()

    def build_app(self) -> None:
        app = self.selected_app()
        if app is None:
            self.status_var.set("No RAM app selected")
            return
        self.run_command([
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(BUILD_DIR / "build_ram_app.ps1"),
            "-Name",
            app.name,
            "-Source",
            app.source,
            "-Startup",
            app.startup,
        ])

    def download_app(self) -> None:
        port = self.port_var.get().strip()
        if not port:
            self.status_var.set("Select a COM port first")
            return

        app = self.selected_app()
        if app is None:
            self.status_var.set("No RAM app selected")
            return
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
            app.name,
            "-Source",
            app.source,
            "-Startup",
            app.startup,
        ])


if __name__ == "__main__":
    LoaderGui().mainloop()
