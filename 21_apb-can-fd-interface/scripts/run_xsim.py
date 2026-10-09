"""Vivado XSim compile/elaborate/simulate regression, with logs + WDB + VCD.

Usage: python scripts/run_xsim.py [--vivado-bin PATH] [--smoke]
An ASCII temporary workspace avoids Windows Vivado Unicode path limitations.
The tested source hashes and actual tool commands are saved with the results.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results" / "xsim"


def find_bin(value):
    candidates = [value, os.environ.get("VIVADO_BIN"),
                  "C:/AMDDesignTools_vivado/2025.2/Vivado/bin"]
    found = shutil.which("xvlog.bat") or shutil.which("xvlog")
    if found:
        candidates.append(str(Path(found).parent))
    for candidate in candidates:
        if candidate and any((Path(candidate)/name).exists() for name in ("xvlog.bat","xvlog")):
            return Path(candidate)
    raise SystemExit("Set VIVADO_BIN or pass --vivado-bin with the Vivado bin directory.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vivado-bin")
    parser.add_argument("--smoke", action="store_true", help="Run the default bridge configuration only")
    args = parser.parse_args()
    vivado_bin = find_bin(args.vivado_bin)
    RESULTS.mkdir(parents=True,exist_ok=True)
    manifest = RESULTS / ("smoke_summary.json" if args.smoke else "verification_summary.json")
    manifest.unlink(missing_ok=True)
    work = Path(tempfile.mkdtemp(prefix="apb_can_xsim_"))
    if not str(work).isascii():
        raise SystemExit("XSim staging path must be ASCII; set TEMP/TMP to an ASCII path.")
    sources = [*sorted((ROOT/"rtl").glob("*.sv")), *sorted((ROOT/"tb").glob("*.sv"))]
    hashes = {}
    for source in sources:
        relative = source.relative_to(ROOT)
        destination = work/relative
        destination.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,destination)
        hashes[relative.as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
    (work/"results").mkdir()
    commands = []

    def run(tool,arguments,label,timeout=150):
        executable = vivado_bin/(tool+(".bat" if os.name=="nt" else ""))
        command = [str(executable),*arguments]
        if tool in ("xelab","xsim"):
            # Vivado's Windows batch loader splits unquoted NAME=VALUE.
            # A native option file preserves generic_top and testplusarg values.
            options = work/f"{label}.args"
            options.write_text("\n".join('"'+arg+'"' for arg in arguments)+"\n",encoding="ascii")
            shutil.copy2(options,RESULTS/options.name)
            command = [str(executable),"--file",options.name]
        commands.append(dict(label=label,cwd=str(work),command=command,arguments=arguments))
        result = subprocess.run(command,cwd=work,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
            text=True,encoding="utf-8",errors="replace",timeout=timeout)
        (RESULTS/f"{label}.log").write_text(result.stdout,encoding="utf-8")
        (RESULTS/"commands.json").write_text(json.dumps(commands,indent=2)+"\n",encoding="utf-8")
        if result.returncode or re.search(r"^(?:ERROR:|FATAL_ERROR:)",result.stdout,re.M):
            print(result.stdout)
            raise SystemExit(f"FAILED {label}; workspace preserved at {work}")
        return result.stdout

    version=run("xvlog",["-version"],"tool_version").strip()
    run("xvlog",["--sv","--define","XSIM",*[p.relative_to(ROOT).as_posix() for p in sources]],"compile")
    print(f"Compiled with {version}",flush=True)
    configs=[("bridge",4,8,20261009)]
    if not args.smoke:
        configs += [("bridge",4,8,42),("bridge",4,8,9173),("bridge",1,1,20261009),
                    ("bridge",3,5,20261009),*[('fifo',d,0,0) for d in (1,3,4,8)]]
    elaborated=set()
    entries=[]
    for kind,tx,rx,seed in configs:
        top="tb_apb_can_bridge" if kind=="bridge" else "tb_frame_fifo"
        snapshot=f"{kind}_tx{tx}_rx{rx}" if kind=="bridge" else f"fifo_depth{tx}"
        name=f"{snapshot}_seed{seed}" if kind=="bridge" else snapshot
        if snapshot not in elaborated:
            generics=["--generic_top",f"TX_DEPTH={tx}","--generic_top",f"RX_DEPTH={rx}"] if kind=="bridge" else ["--generic_top",f"DEPTH={tx}"]
            run("xelab",[top,"--snapshot",snapshot,"--debug","all","--rangecheck",*generics],f"{snapshot}_elaborate")
            elaborated.add(snapshot)
        # Generic overrides decorate the top scope (including an escaped name).
        # Relative queries resolve against XSim's actual current top scope.
        tcl=["log_wave -r [current_scope]",f"open_vcd results/{name}.vcd"]
        if kind=="bridge":
            for pattern in ("i*","o*","dut/*","dut/u_tx_ctrl/*"):
                tcl.append(f"set objects [get_objects {pattern}]")
                tcl.append('if {[llength $objects] == 0} {error "Missing waveform objects"}')
                tcl.append("log_vcd $objects")
        else:
            tcl += ["log_vcd [get_objects i*]","log_vcd [get_objects o*]"]
        tcl += ["run all","close_vcd","quit"]
        (work/f"{name}.tcl").write_text("\n".join(tcl)+"\n",encoding="ascii")
        shutil.copy2(work/f"{name}.tcl",RESULTS/f"{name}.tcl")
        output=run("xsim",[snapshot,"--tclbatch",f"{name}.tcl","--onerror","quit","--onfinish","stop",
                           "--wdb",f"results/{name}.wdb","--testplusarg",f"SEED={seed}"],name)
        if kind=="bridge":
            match=re.search(r"PASS bridge: cases=(\d+) checks=(\d+) accepted=(\d+)",output)
            if not match: raise SystemExit(f"Missing PASS marker for {name}")
            record=dict(name=name,kind=kind,tx_depth=tx,rx_depth=rx,seed=seed,
                cases=int(match[1]),checks=int(match[2]),accepted=int(match[3]),passed=True)
        else:
            match=re.search(r"PASS fifo: depth=(\d+) steps=(\d+) checks=(\d+) full_replace=(\d+) empty_both=(\d+) overflow=(\d+) underflow=(\d+)",output)
            if not match: raise SystemExit(f"Missing PASS marker for {name}")
            record=dict(name=name,kind=kind,depth=tx,steps=int(match[2]),checks=int(match[3]),
                full_replace=int(match[4]),empty_both=int(match[5]),overflow=int(match[6]),underflow=int(match[7]),passed=True)
        entries.append(record)
        for suffix in (".vcd",".wdb"):
            artifact=work/"results"/(name+suffix)
            if not artifact.exists() or artifact.stat().st_size==0:
                raise SystemExit(f"Missing waveform artifact: {artifact}")
            if suffix==".vcd" and "$var" not in artifact.read_text(encoding="utf-8"):
                raise SystemExit(f"Waveform has no signals: {artifact}")
            shutil.copy2(artifact,RESULTS/artifact.name)
        print(match[0],name,flush=True)
    summary=dict(tool=version,runs=entries,total_checks=sum(r['checks'] for r in entries),
        all_passed=True,source_sha256=hashes,workspace=str(work),compile_define="XSIM")
    manifest.write_text(json.dumps(summary,indent=2)+"\n",encoding="utf-8")
    print(f"PASS XSim: {len(entries)} runs; {summary['total_checks']} checks",flush=True)


if __name__=="__main__":
    main()
