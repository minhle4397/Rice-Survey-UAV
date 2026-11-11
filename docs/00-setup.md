# Giai đoạn 0 – Repo và môi trường phát triển

**Mục tiêu:** repo GitHub chạy được CI, PX4 đúng phiên bản stable, và một vòng mô phỏng hoàn chỉnh: PX4 SITL ↔ Gazebo ↔ QGroundControl ↔ ROS 2.

**Xong khi:**

- [ ] Repo `rice-survey-uav` có trên GitHub, CI xanh.
- [ ] `git describe --tags` trong PX4 trả về `v1.17.0`.
- [ ] `make px4_sitl gz_x500` cất cánh được, QGC thấy drone.
- [ ] `make holybro_kakuteh7mini_default` build thành công.
- [ ] `ros2 topic echo /fmu/out/vehicle_odometry` có dữ liệu.
- [ ] `./scripts/check_env.sh` không còn dòng FAIL.

Mỗi lệnh bên dưới chạy trong terminal Ubuntu. Dòng bắt đầu bằng `#` là chú thích, không cần gõ.

---

## 1. Đưa repo lên GitHub

### 1.1 Kiểm tra SSH key với GitHub

```bash
ssh -T git@github.com
```

Kết quả đúng: `Hi <username>! You've successfully authenticated...`. Nếu báo `Permission denied`, thêm khóa công khai `~/.ssh/id_ed25519.pub` vào GitHub → Settings → SSH and GPG keys.

### 1.2 Cấu hình git (một lần trên máy)

```bash
git config --global user.name "Họ Tên Của Bạn"
git config --global user.email "email-dang-ky-github@example.com"
```

Email phải trùng email trên GitHub thì commit mới hiện trên profile (ô xanh contribution).

### 1.3 Giải nén bộ khung và tạo repo

```bash
cd ~
unzip ~/Downloads/rice-survey-uav.zip
cd ~/rice-survey-uav
chmod +x scripts/*.sh
```

Sửa dòng `Copyright (c) 2026, <YOUR NAME>` trong `LICENSE` thành tên của bạn. Sau đó:

```bash
git init -b main
git add .
git commit -m "Initial project skeleton"
```

Cách A – dùng GitHub CLI (chọn **SSH** khi được hỏi giao thức):

```bash
sudo apt install gh -y
gh auth login
gh repo create rice-survey-uav --public --source=. --remote=origin --push
```

Cách B – tạo repo trống trên github.com (không tick README/LICENSE/.gitignore), rồi:

```bash
git remote add origin git@github.com:<username>/rice-survey-uav.git
git push -u origin main
```

Mở tab **Actions** của repo: workflow `CI` phải chạy xanh.

---

## 2. Đưa PX4 về bản stable v1.17.0

PX4 của bạn đang ở `v1.18.0-beta1-672-...`, tức nhánh `main` (bản phát triển, thay đổi hằng ngày). Đồ án cần một phiên bản cố định để:

- kết quả mô phỏng tái lập được, ghi được vào báo cáo;
- `px4_msgs` khớp chính xác định nghĩa message (nếu lệch, node ROS 2 sẽ không nhận được dữ liệu);
- firmware nạp lên Kakute là bản đã được kiểm thử.

```bash
cd ~/PX4-Autopilot
git status
```

Nếu `git status` có file bị sửa mà bạn muốn giữ, chạy `git stash` trước. Sau đó:

```bash
git fetch origin --tags
git tag -l 'v1.17*'
```

Chọn bản `v1.17.x` mới nhất **không** có đuôi `-rc`, `-beta`, `-alpha`. Tại thời điểm viết là `v1.17.0`:

```bash
git checkout v1.17.0
git switch -c rice-uav-v1.17.0
git submodule sync --recursive
git submodule update --init --recursive
make distclean
git describe --tags
```

`git switch -c` tạo nhánh cục bộ để GĐ 1 cài model/airframe vào mà không đụng tag gốc. Lệnh cuối phải in `v1.17.0`.

> Nếu sau này có `v1.17.1`, thay số phiên bản ở bước trên, đồng thời sửa `PX4_TAG_EXPECTED` trong `scripts/check_env.sh` và bảng phiên bản trong `README.md`.

### 2.1 Chạy script cài đặt của PX4

Script này cài toolchain ARM (build cho Kakute), Gazebo Harmonic và thư viện Python cần thiết. Chạy lại cả khi bạn đã cài trước đó, vì phiên bản phụ thuộc có thể đổi giữa `main` và `v1.17.0`.

```bash
bash ./Tools/setup/ubuntu.sh
```

Khởi động lại máy sau khi chạy xong.

### 2.2 Chạy thử mô phỏng

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500
```

Lần đầu build mất 5–15 phút. Khi cửa sổ Gazebo hiện drone x500 và terminal có dấu nhắc `pxh>`, gõ:

```
commander takeoff
```

Drone cất cánh lên ~2.5 m. Tiếp theo:

```
commander land
```

Thoát bằng `Ctrl+C`.

### 2.3 Build thử firmware cho Kakute H7 Mini

Chưa nạp lên mạch, chỉ kiểm tra toolchain:

```bash
make holybro_kakuteh7mini_default
ls build/holybro_kakuteh7mini_default/*.px4
```

Có file `holybro_kakuteh7mini_default.px4` là thành công. File này sẽ được nạp ở GĐ 6.

---

## 3. Cài QGroundControl

```bash
sudo usermod -aG dialout "$(id -un)"
sudo apt remove modemmanager -y
sudo apt install gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl -y
sudo apt install libfuse2 libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor-dev -y
```

**Đăng xuất rồi đăng nhập lại** để nhóm `dialout` có hiệu lực.

Tải `QGroundControl-x86_64.AppImage` từ trang chính thức <https://docs.qgroundcontrol.com/master/en/qgc-user-guide/getting_started/download_and_install.html>, chép vào thư mục home:

```bash
mv ~/Downloads/QGroundControl*.AppImage ~/
chmod +x ~/QGroundControl*.AppImage
```

Chạy `make px4_sitl gz_x500` trước, rồi mở QGC: QGC tự kết nối qua UDP 14550. Thử bấm **Takeoff** trên QGC và kéo thanh trượt xác nhận.

---

## 4. Cài Micro XRCE-DDS Agent

Agent là cầu nối giữa PX4 (uXRCE-DDS client) và ROS 2. Theo tài liệu PX4 v1.17, build từ mã nguồn bản v2.4.3:

```bash
cd ~
git clone -b v2.4.3 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git
cd Micro-XRCE-DDS-Agent
mkdir build && cd build
cmake ..
make -j"$(nproc)"
sudo make install
sudo ldconfig /usr/local/lib/
```

Kiểm tra:

```bash
MicroXRCEAgent --help | head -3
```

Nếu bước `cmake` hoặc `make` báo lỗi, dùng bản snap thay thế (lệnh chạy khi đó là `micro-xrce-dds-agent`, các script trong repo nhận cả hai tên):

```bash
sudo snap install micro-xrce-dds-agent --edge
```

---

## 5. Workspace ROS 2 trong repo

`px4_msgs` không được lưu trong repo của bạn. Nó được kéo về theo file `ros2_ws/px4.repos`, ghim ở nhánh `release/1.17` cho khớp với PX4.

```bash
sudo apt install python3-vcstool python3-colcon-common-extensions -y
cd ~/rice-survey-uav/ros2_ws
vcs import src < px4.repos
source /opt/ros/jazzy/setup.bash
colcon build
```

Build `px4_msgs` mất vài phút. Thêm hai dòng sau vào cuối `~/.bashrc` để mỗi terminal mới tự nạp môi trường:

```bash
echo 'source /opt/ros/jazzy/setup.bash' >> ~/.bashrc
echo '[ -f ~/rice-survey-uav/ros2_ws/install/setup.bash ] && source ~/rice-survey-uav/ros2_ws/install/setup.bash' >> ~/.bashrc
```

---

## 6. Chạy thử toàn bộ vòng mô phỏng

**Terminal 1** – Agent + PX4 SITL + Gazebo + QGC:

```bash
cd ~/rice-survey-uav
./scripts/run_sitl.sh
```

Trong `pxh>` kiểm tra client DDS đã kết nối:

```
uxrce_dds_client status
```

**Terminal 2** – đọc dữ liệu từ ROS 2:

```bash
ros2 topic list | grep fmu
```

Bạn sẽ thấy các topic `/fmu/out/...` và `/fmu/in/...`. Một số topic có hậu tố phiên bản (ví dụ `/fmu/out/vehicle_status_v1`); luôn dùng đúng tên mà `ros2 topic list` in ra.

```bash
ros2 topic echo /fmu/out/vehicle_odometry --once
```

Cất cánh bằng QGC rồi chạy lại lệnh trên: giá trị `position` (hệ NED, trục z âm khi bay lên) phải thay đổi. Nếu lệnh `echo` không in gì, thử thêm `--qos-reliability best_effort`.

---

## 7. Kiểm tra môi trường và commit

```bash
cd ~/rice-survey-uav
./scripts/check_env.sh
```

Sửa hết các dòng `[FAIL]` theo gợi ý in ra. Sau đó đánh dấu `[x] Phase 0` trong `README.md` và commit:

```bash
git add README.md
git commit -m "Phase 0: development environment ready (PX4 v1.17.0, ROS 2 Jazzy, Gazebo Harmonic)"
git push
```

---

## 8. Lỗi thường gặp

| Hiện tượng | Nguyên nhân | Cách sửa |
| --- | --- | --- |
| `make px4_sitl gz_x500` báo thiếu `gz` | Chưa cài Gazebo Harmonic | Chạy lại `bash ./Tools/setup/ubuntu.sh`, khởi động lại |
| Gazebo mở nhưng drone không xuất hiện, PX4 chờ mãi | Gazebo khởi động chậm lần đầu (tải model) | Đợi 1–2 phút; hoặc chạy lại lệnh |
| Lỗi build sau khi `git checkout` | Build cũ của `main` còn sót | `make distclean` rồi build lại |
| `ros2 topic list` không có `/fmu/...` | Agent chưa chạy, hoặc khác `ROS_DOMAIN_ID` | Kiểm tra `results/logs/agent.log`; `echo $ROS_DOMAIN_ID` ở cả hai terminal |
| Có topic nhưng `echo` báo lỗi kiểu message | `px4_msgs` lệch phiên bản PX4 | Kiểm tra nhánh `release/1.17`, `colcon build` lại |
| QGC không mở được cổng USB | Chưa vào nhóm `dialout` hoặc ModemManager chiếm cổng | Mục 3, nhớ đăng xuất/đăng nhập |

Gặp lỗi khác: gửi nguyên văn 20–30 dòng cuối của terminal.
