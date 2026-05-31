#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/docs/tool_runs"
mkdir -p "$LOG_DIR"

run_block() {
  local name="$1"
  local tb_dir="$ROOT_DIR/$name/tb"

  echo "===== $name: make clean run =====" | tee "$LOG_DIR/${name}_run_summary.txt"
  (
    cd "$tb_dir" || exit 1
    make clean
    make run
  ) 2>&1 | tee "$LOG_DIR/${name}_vcs_run.txt"

  local run_status=${PIPESTATUS[0]}

  if [ "$run_status" -eq 0 ] && [ -d "$tb_dir/simv.vdb" ]; then
    echo "===== $name: urg coverage report =====" | tee -a "$LOG_DIR/${name}_run_summary.txt"
    (
      cd "$tb_dir" || exit 1
      make urg
    ) 2>&1 | tee "$LOG_DIR/${name}_urg.txt"
  else
    echo "Skip URG for $name because VCS run failed or simv.vdb is missing." | tee -a "$LOG_DIR/${name}_run_summary.txt"
  fi

  if [ -f "$tb_dir/novas.fsdb" ]; then
    ls -lh "$tb_dir/novas.fsdb" | tee -a "$LOG_DIR/${name}_run_summary.txt"
  else
    echo "No novas.fsdb generated for $name." | tee -a "$LOG_DIR/${name}_run_summary.txt"
  fi

  return "$run_status"
}

echo "Tool versions" | tee "$LOG_DIR/tool_versions_latest.txt"
vcs -ID 2>&1 | tee -a "$LOG_DIR/tool_versions_latest.txt"
verdi -version 2>&1 | tee -a "$LOG_DIR/tool_versions_latest.txt"

status=0
for block in adder ram fifo; do
  run_block "$block" || status=1
done

exit "$status"
