#!/usr/bin/env bash
# Chạy mô phỏng: Micro XRCE-DDS Agent + PX4 SITL + Gazebo (+ QGroundControl nếu tìm thấy).
# Cách dùng:  ./scripts/run_sitl.sh               (model mặc định gz_x500)
#             MODEL=gz_rice_uav ./scripts/run_sitl.sh   (từ GĐ 1)
#             HEADLESS=1 ./scripts/run_sitl.sh    (không mở cửa sổ Gazebo)
set -euo pipefail

PX4_DIR="${PX4_DIR:-$HOME/PX4-Autopilot}"
MODEL="${MODEL:-gz_x500}"
AGENT_PORT="${AGENT_PORT:-8888}"
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/results/logs"
mkdir -p "$LOG_DIR"

AGENT_BIN="$(command -v MicroXRCEAgent || command -v micro-xrce-dds-agent || true)"
if [ -z "$AGENT_BIN" ]; then echo "Không tìm thấy Micro XRCE-DDS Agent. Xem docs/00-setup.md." >&2; exit 1; fi

pids=()
cleanup() { for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done; }
trap cleanup EXIT INT TERM

echo ">> Micro XRCE-DDS Agent trên UDP $AGENT_PORT (log: $LOG_DIR/agent.log)"
"$AGENT_BIN" udp4 -p "$AGENT_PORT" > "$LOG_DIR/agent.log" 2>&1 &
pids+=($!)

QGC="$(ls "$HOME"/QGroundControl*.AppImage 2>/dev/null | head -1 || true)"
if [ -n "$QGC" ]; then
  echo ">> QGroundControl: $QGC"
  "$QGC" > "$LOG_DIR/qgc.log" 2>&1 &
  pids+=($!)
fi

echo ">> PX4 SITL, model $MODEL"
cd "$PX4_DIR"
if [ "${HEADLESS:-0}" = "1" ]; then export HEADLESS=1; fi
make px4_sitl "$MODEL"
