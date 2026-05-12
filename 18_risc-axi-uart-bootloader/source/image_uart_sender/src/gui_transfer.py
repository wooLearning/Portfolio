from __future__ import annotations

import queue
import subprocess
import sys
import threading
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

from protocol import now_stamp
from serial_utils import default_output_dir, list_ports


class TransferGui(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.root_dir = Path(__file__).resolve().parents[1]
        self.out_dir = default_output_dir(Path(__file__))
        self.process: subprocess.Popen[str] | None = None
        self.output_queue: queue.Queue[str] = queue.Queue()

        self.title("FPGA UART Image Transfer")
        self.geometry("980x680")
        self.minsize(860, 560)

        self.master_port = tk.StringVar(value="COM4")
        self.slave_port = tk.StringVar(value="COM7")
        self.baud = tk.StringVar(value="115200")
        self.mode = tk.StringVar(value="RGB")
        self.width = tk.StringVar(value="64")
        self.height = tk.StringVar(value="64")
        self.raw = tk.BooleanVar(value=True)
        self.image_path = tk.StringVar(value=str(self.root_dir / "images" / "rainbow64x64_rgb888.png"))
        self.out_path = tk.StringVar(value=str(self.out_dir / f"received_{now_stamp()}.png"))
        self.status = tk.StringVar(value="IDLE")
        self.result = tk.StringVar(value="READY")

        self._build_ui()
        self.refresh_ports()
        self.after(100, self._drain_output_queue)

    def _build_ui(self) -> None:
        self.columnconfigure(0, weight=1)
        self.rowconfigure(2, weight=1)

        controls = ttk.Frame(self, padding=12)
        controls.grid(row=0, column=0, sticky="ew")
        for col in range(10):
            controls.columnconfigure(col, weight=1)

        ttk.Label(controls, text="Master TX Port").grid(row=0, column=0, sticky="w")
        self.master_combo = ttk.Combobox(controls, textvariable=self.master_port, width=14)
        self.master_combo.grid(row=1, column=0, sticky="ew", padx=(0, 8))

        ttk.Label(controls, text="Slave RX Port").grid(row=0, column=1, sticky="w")
        self.slave_combo = ttk.Combobox(controls, textvariable=self.slave_port, width=14)
        self.slave_combo.grid(row=1, column=1, sticky="ew", padx=(0, 8))

        ttk.Label(controls, text="Baud").grid(row=0, column=2, sticky="w")
        ttk.Entry(controls, textvariable=self.baud, width=12).grid(row=1, column=2, sticky="ew", padx=(0, 8))

        ttk.Label(controls, text="Mode").grid(row=0, column=3, sticky="w")
        ttk.Combobox(controls, textvariable=self.mode, values=["L", "RGB"], width=8, state="readonly").grid(
            row=1, column=3, sticky="ew", padx=(0, 8)
        )

        ttk.Label(controls, text="Width").grid(row=0, column=4, sticky="w")
        ttk.Entry(controls, textvariable=self.width, width=8).grid(row=1, column=4, sticky="ew", padx=(0, 8))

        ttk.Label(controls, text="Height").grid(row=0, column=5, sticky="w")
        ttk.Entry(controls, textvariable=self.height, width=8).grid(row=1, column=5, sticky="ew", padx=(0, 8))

        ttk.Checkbutton(controls, text="Raw", variable=self.raw).grid(row=1, column=6, sticky="w", padx=(0, 8))
        ttk.Button(controls, text="Refresh Ports", command=self.refresh_ports).grid(
            row=1, column=7, sticky="ew", padx=(0, 8)
        )
        self.run_button = ttk.Button(controls, text="Run", command=self.run_transfer)
        self.run_button.grid(row=1, column=8, sticky="ew", padx=(0, 8))
        self.stop_button = ttk.Button(controls, text="Stop", command=self.stop_transfer, state="disabled")
        self.stop_button.grid(row=1, column=9, sticky="ew")

        files = ttk.Frame(self, padding=(12, 0, 12, 12))
        files.grid(row=1, column=0, sticky="ew")
        files.columnconfigure(1, weight=1)

        ttk.Label(files, text="Input Image").grid(row=0, column=0, sticky="w", padx=(0, 8))
        ttk.Entry(files, textvariable=self.image_path).grid(row=0, column=1, sticky="ew", padx=(0, 8))
        ttk.Button(files, text="Browse", command=self.pick_image).grid(row=0, column=2, sticky="ew")

        ttk.Label(files, text="Output Image").grid(row=1, column=0, sticky="w", padx=(0, 8), pady=(8, 0))
        ttk.Entry(files, textvariable=self.out_path).grid(row=1, column=1, sticky="ew", padx=(0, 8), pady=(8, 0))
        output_buttons = ttk.Frame(files)
        output_buttons.grid(row=1, column=2, sticky="ew", pady=(8, 0))
        ttk.Button(output_buttons, text="Browse", command=self.pick_output).pack(side="left", fill="x", expand=True)
        ttk.Button(output_buttons, text="New Name", command=self.new_output_name).pack(
            side="left",
            fill="x",
            expand=True,
            padx=(8, 0),
        )

        middle = ttk.PanedWindow(self, orient="horizontal")
        middle.grid(row=2, column=0, sticky="nsew", padx=12, pady=(0, 12))

        left = ttk.Frame(middle, padding=12)
        middle.add(left, weight=1)
        left.columnconfigure(0, weight=1)
        left.rowconfigure(4, weight=1)

        ttk.Label(left, text="Status").grid(row=0, column=0, sticky="w")
        ttk.Label(left, textvariable=self.status, font=("Segoe UI", 16, "bold")).grid(row=1, column=0, sticky="w")
        ttk.Label(left, text="Result").grid(row=2, column=0, sticky="w", pady=(16, 0))
        ttk.Label(left, textvariable=self.result, font=("Segoe UI", 22, "bold")).grid(row=3, column=0, sticky="w")

        summary = (
            "Master TX Port: PC -> master FPGA UART\n"
            "Slave RX Port: slave FPGA UART -> PC\n"
            "Raw mode: FPGA receives only pixel bytes\n"
            "Output: received PNG, RX text dump, diff PNG, JSON log"
        )
        ttk.Label(left, text=summary, justify="left").grid(row=4, column=0, sticky="nw", pady=(24, 0))

        right = ttk.Frame(middle, padding=12)
        middle.add(right, weight=3)
        right.columnconfigure(0, weight=1)
        right.rowconfigure(1, weight=1)
        ttk.Label(right, text="Terminal Output").grid(row=0, column=0, sticky="w")
        self.output = tk.Text(right, wrap="word", height=18)
        self.output.grid(row=1, column=0, sticky="nsew")
        scroll = ttk.Scrollbar(right, orient="vertical", command=self.output.yview)
        scroll.grid(row=1, column=1, sticky="ns")
        self.output.configure(yscrollcommand=scroll.set)

    def refresh_ports(self) -> None:
        ports = [port["device"] for port in list_ports()]
        self.master_combo["values"] = ports
        self.slave_combo["values"] = ports
        if ports:
            if self.master_port.get() not in ports:
                self.master_port.set(ports[0])
            if self.slave_port.get() not in ports:
                if len(ports) > 1:
                    self.slave_port.set(ports[1])
                else:
                    self.slave_port.set(ports[0])
            self.status.set(f"PORTS FOUND: {', '.join(ports)}")
        else:
            self.status.set("NO COM PORTS FOUND")

    def pick_image(self) -> None:
        path = filedialog.askopenfilename(
            initialdir=self.root_dir,
            filetypes=[("Image files", "*.png;*.jpg;*.jpeg;*.bmp"), ("All files", "*.*")],
        )
        if path:
            self.image_path.set(path)

    def new_output_name(self) -> None:
        self.out_path.set(str(self.out_dir / f"received_{now_stamp()}.png"))

    def pick_output(self) -> None:
        path = filedialog.asksaveasfilename(
            initialdir=self.out_dir,
            initialfile=f"received_{now_stamp()}.png",
            defaultextension=".png",
            filetypes=[("PNG image", "*.png"), ("All files", "*.*")],
        )
        if path:
            self.out_path.set(path)

    def run_transfer(self) -> None:
        if self.process is not None:
            return
        if not self.master_port.get() or not self.slave_port.get():
            messagebox.showerror("Missing COM port", "Master and slave COM ports are required.")
            return
        if self.master_port.get() == self.slave_port.get():
            messagebox.showwarning("Same COM port", "Master and slave ports are the same. Check wiring/selection.")
        try:
            width = int(self.width.get())
            height = int(self.height.get())
        except ValueError:
            messagebox.showerror("Invalid image size", "Width and height must be numbers.")
            return
        if width <= 0 or height <= 0:
            messagebox.showerror("Invalid image size", "Width and height must be positive.")
            return

        self.output.delete("1.0", "end")
        self.status.set("RUNNING")
        self.result.set("WAITING")
        self.run_button.configure(state="disabled")
        self.stop_button.configure(state="normal")

        cmd = [
            sys.executable,
            "-u",
            str(Path(__file__).with_name("transfer_compare.py")),
            "--tx-port",
            self.master_port.get(),
            "--rx-port",
            self.slave_port.get(),
            "--baud",
            self.baud.get(),
            "--image",
            self.image_path.get(),
            "--mode",
            self.mode.get(),
            "--width",
            str(width),
            "--height",
            str(height),
            "--out",
            self.out_path.get(),
        ]
        if self.raw.get():
            cmd.append("--raw")

        self._append_output("Running:\n" + " ".join(cmd) + "\n\n")
        threading.Thread(target=self._run_subprocess, args=(cmd,), daemon=True).start()

    def stop_transfer(self) -> None:
        if self.process is not None:
            self.process.terminate()
            self.status.set("STOPPING")

    def _run_subprocess(self, cmd: list[str]) -> None:
        try:
            self.process = subprocess.Popen(
                cmd,
                cwd=self.root_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            assert self.process.stdout is not None
            for line in self.process.stdout:
                self.output_queue.put(line)
            return_code = self.process.wait()
            self.output_queue.put(f"\nProcess exited with code {return_code}\n")
            self.output_queue.put("__PASS__" if return_code == 0 else "__FAIL__")
        except Exception as exc:
            self.output_queue.put(f"\nGUI runner error: {exc!r}\n")
            self.output_queue.put("__FAIL__")
        finally:
            self.process = None

    def _drain_output_queue(self) -> None:
        while True:
            try:
                item = self.output_queue.get_nowait()
            except queue.Empty:
                break
            if item == "__PASS__":
                self.status.set("DONE")
                text = self.output.get("1.0", "end")
                if "Compare: PASS" in text:
                    self.result.set("PASS")
                elif "Compare: FAIL" in text:
                    self.status.set("FAILED")
                    self.result.set("FAIL")
                else:
                    self.result.set("DONE")
                self.run_button.configure(state="normal")
                self.stop_button.configure(state="disabled")
            elif item == "__FAIL__":
                self.status.set("FAILED")
                self.result.set("FAIL")
                self.run_button.configure(state="normal")
                self.stop_button.configure(state="disabled")
            else:
                self._append_output(item)
                if "RX armed" in item:
                    self.status.set("RX ARMED")
                elif "Sending" in item:
                    self.status.set("SENDING")
                elif "Received" in item:
                    self.status.set("RECEIVED")
                elif "Compare: PASS" in item:
                    self.result.set("PASS")
                elif "Compare: FAIL" in item:
                    self.result.set("FAIL")
        self.after(100, self._drain_output_queue)

    def _append_output(self, text: str) -> None:
        self.output.insert("end", text)
        self.output.see("end")


def main() -> int:
    app = TransferGui()
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
