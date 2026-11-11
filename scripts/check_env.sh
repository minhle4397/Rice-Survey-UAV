#!/usr/bin/env bash
# Kiểm tra môi trường phát triển cho Rice Survey UAV.
# Cách dùng:  ./scripts/check_env.sh            (PX4 ở ~/PX4-Autopilot)
#             PX4_DIR=/duong/dan/PX4 ./scripts/check_env.sh
set -u

PX4_DIR="${PX4_DIR:-$HOME/PX4-Autopilot}"
PX4_TAG_EXPECTED="${PX4_TAG_EXPECTED:-v1.17.0}"
PX4_MSGS_BRANCH_EXPECTED="release/1.17"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass=0; fail=0; warn=0
ok()   { printf '  \e[32m[ OK ]\e[0m %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf '  \e[31m[FAIL]\e[0m %s\n         -> %s\n' "$1" "$2"; fail=$((fail+1)); }
note() { printf '  \e[33m[WARN]\e[0m %s\n         -> %s\n' "$1" "$2"; warn=$((warn+1)); }

echo "== Hệ điều hành"
if grep -q 'VERSION_ID="24.04"' /etc/os-release 2>/dev/null; then ok "Ubuntu 24.04"
else note "Không phải Ubuntu 24.04" "Hướng dẫn viết cho 24.04, bản khác có thể lệch phiên bản Gazebo/ROS 2"; fi

echo "== PX4-Autopilot ($PX4_DIR)"
if [ -d "$PX4_DIR/.git" ]; then
  tag="$(git -C "$PX4_DIR" describe --tags 2>/dev/null)"
  if [ "$tag" = "$PX4_TAG_EXPECTED" ]; then ok "PX4 đang ở $tag"
  else bad "PX4 đang ở '$tag', cần $PX4_TAG_EXPECTED" "Xem docs/00-setup.md, mục 1"; fi
  if git -C "$PX4_DIR" submodule status --recursive 2>/dev/null | grep -qE '^[-+]'; then
    bad "Submodule PX4 chưa đồng bộ" "git -C $PX4_DIR submodule update --init --recursive"
  else ok "Submodule PX4 đồng bộ"; fi
else bad "Không thấy PX4 ở $PX4_DIR" "Đặt biến PX4_DIR hoặc clone PX4 về đó"; fi

echo "== Toolchain"
if command -v arm-none-eabi-gcc >/dev/null; then ok "arm-none-eabi-gcc $(arm-none-eabi-gcc -dumpversion)"
else bad "Thiếu arm-none-eabi-gcc (cần để build firmware cho Kakute)" "bash $PX4_DIR/Tools/setup/ubuntu.sh"; fi
if command -v gz >/dev/null; then
  v="$(gz sim --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  case "$v" in 8.*) ok "Gazebo Harmonic (gz sim $v)";; *) note "gz sim $v" "PX4 v1.17 trên Ubuntu 24.04 dùng Gazebo Harmonic (gz sim 8.x)";; esac
else bad "Thiếu Gazebo (gz)" "bash $PX4_DIR/Tools/setup/ubuntu.sh"; fi

echo "== ROS 2 và uXRCE-DDS"
if [ -f /opt/ros/jazzy/setup.bash ]; then ok "ROS 2 Jazzy ở /opt/ros/jazzy"
else bad "Không thấy ROS 2 Jazzy" "https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html"; fi
if command -v colcon >/dev/null; then ok "colcon"; else bad "Thiếu colcon" "sudo apt install python3-colcon-common-extensions"; fi
if command -v vcs >/dev/null; then ok "vcstool"; else bad "Thiếu vcstool" "sudo apt install python3-vcstool"; fi
if command -v MicroXRCEAgent >/dev/null || command -v micro-xrce-dds-agent >/dev/null; then ok "Micro XRCE-DDS Agent"
else bad "Thiếu Micro XRCE-DDS Agent" "Xem docs/00-setup.md, mục 4"; fi
msgs="$REPO_ROOT/ros2_ws/src/px4_msgs"
if [ -d "$msgs/.git" ]; then
  b="$(git -C "$msgs" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ "$b" = "$PX4_MSGS_BRANCH_EXPECTED" ] && ok "px4_msgs ở nhánh $b" \
    || bad "px4_msgs ở nhánh '$b', cần $PX4_MSGS_BRANCH_EXPECTED" "cd ros2_ws && rm -rf src/px4_msgs && vcs import src < px4.repos"
else note "Chưa có ros2_ws/src/px4_msgs" "cd ros2_ws && vcs import src < px4.repos"; fi

echo "== QGroundControl và cổng USB"
if ls "$HOME"/QGroundControl*.AppImage >/dev/null 2>&1 || command -v QGroundControl >/dev/null; then ok "QGroundControl"
else note "Không thấy QGroundControl*.AppImage trong $HOME" "Xem docs/00-setup.md, mục 3"; fi
if id -nG "$USER" | grep -qw dialout; then ok "User thuộc nhóm dialout"
else bad "User chưa thuộc nhóm dialout (không mở được cổng USB của FC)" "sudo usermod -aG dialout $USER, rồi đăng xuất/đăng nhập lại"; fi
if dpkg -s modemmanager >/dev/null 2>&1; then note "modemmanager đang cài" "sudo apt remove modemmanager -y (nó chiếm cổng USB của FC)"
else ok "Không có modemmanager"; fi

echo
echo "Kết quả: $pass OK, $warn WARN, $fail FAIL"
[ "$fail" -eq 0 ]
