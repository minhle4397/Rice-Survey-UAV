#!/usr/bin/env bash
# Link the rice_uav Gazebo model and its PX4 airframe into a PX4-Autopilot tree.
# Files stay in this repo; PX4 only gets symlinks, so edits here take effect
# after the next `make px4_sitl gz_rice_uav`.
#
# Usage:  ./simulation/scripts/install_into_px4.sh
#         PX4_DIR=/path/to/PX4-Autopilot ./simulation/scripts/install_into_px4.sh
set -euo pipefail

PX4_DIR="${PX4_DIR:-$HOME/PX4-Autopilot}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MODEL_NAME="rice_uav"
AIRFRAME_NAME="4050_gz_rice_uav"

MODEL_SRC="$REPO_ROOT/simulation/models/$MODEL_NAME"
AIRFRAME_SRC="$REPO_ROOT/firmware/airframes/$AIRFRAME_NAME"
MODELS_DST="$PX4_DIR/Tools/simulation/gz/models"
AIRFRAMES_DST="$PX4_DIR/ROMFS/px4fmu_common/init.d-posix/airframes"
AIRFRAMES_CMAKE="$AIRFRAMES_DST/CMakeLists.txt"

for path in "$MODEL_SRC/model.sdf" "$AIRFRAME_SRC" "$MODELS_DST" "$AIRFRAMES_CMAKE"; do
  if [ ! -e "$path" ]; then
    echo "error: not found: $path" >&2
    exit 1
  fi
done

ln -sfn "$MODEL_SRC" "$MODELS_DST/$MODEL_NAME"
echo "linked model    -> $MODELS_DST/$MODEL_NAME"

ln -sfn "$AIRFRAME_SRC" "$AIRFRAMES_DST/$AIRFRAME_NAME"
echo "linked airframe -> $AIRFRAMES_DST/$AIRFRAME_NAME"

# Register the airframe so it is packed into the SITL ROMFS (insert after 4001_gz_x500).
if grep -q "^[[:space:]]*$AIRFRAME_NAME\$" "$AIRFRAMES_CMAKE"; then
  echo "airframe already registered in CMakeLists.txt"
else
  sed -i "s/^\([[:space:]]*\)4001_gz_x500\$/&\n\1$AIRFRAME_NAME/" "$AIRFRAMES_CMAKE"
  echo "registered airframe in $AIRFRAMES_CMAKE"
fi

echo "done. Run: cd $PX4_DIR && make px4_sitl gz_$MODEL_NAME"