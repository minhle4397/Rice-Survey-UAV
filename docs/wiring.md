# Đấu dây – Kakute H7 Mini v1.5

Thứ tự cổng dưới đây là của **firmware PX4**, khác với Betaflight. Nguồn: `boards/holybro/kakuteh7mini` trong PX4-Autopilot v1.17.0.

## Bảng cổng UART của PX4

| Pad trên mạch | UART | Thiết bị Linux/NuttX | Vai trò mặc định trong PX4 |
| --- | --- | --- | --- |
| T1 / R1 | USART1 | `/dev/ttyS0` | TELEM1 (MAVLink) |
| T2 / R2 | USART2 | `/dev/ttyS1` | TELEM2 |
| T3 / R3 | USART3 | `/dev/ttyS2` | **NuttX debug console – không dùng cho thiết bị khác** |
| T4 / R4 | UART4 | `/dev/ttyS3` | GPS1 |
| T6 / R6 | USART6 | `/dev/ttyS4` | RC input |
| R7 | UART7 | `/dev/ttyS5` | DShot telemetry |

## Đấu dây

| Thiết bị | Chân thiết bị | Pad Kakute | Ghi chú |
| --- | --- | --- | --- |
| GPS NEO-M8N | TX | **R4** | đấu chéo TX→RX |
| | RX | **T4** | |
| | VCC | 5V | |
| | GND | G | |
| La bàn QMC5883L | SDA | SDA | I2C1, địa chỉ 0x0D |
| | SCL | SCL | |
| | VCC | 5V | |
| | GND | G | |
| ESP32 | GPIO16 (RX2) | **T1** | đấu chéo |
| | GPIO17 (TX2) | **R1** | |
| | VIN (5V) | 5V | **không** cấp vào chân 3V3 của ESP32 |
| | GND | G | |
| Receiver RadioMaster RP1 (CRSF) | TX | **R6** | |
| | RX | **T6** | |
| | 5V | 5V | |
| | GND | G | |
| Caddx Ant | Video | **VTX – Video In** | nối thẳng vào VTX, không qua VI/VO của FC |
| | 5V / GND | 5V / G | |
| VTX analog 5.8 GHz | Power + / GND | B+ / G (pin 3S, qua PDB) | VTX phải nhận được dải 7–26 V |
| | Video In | dây video của Caddx Ant | |
| ESC 1–4 | Signal | M1–M4 | xem thứ tự động cơ bên dưới |
| | GND tín hiệu | G | GND chung với FC |
| Pin 3S | + / − | B+ / G (qua PDB) | FC đo áp pin qua B+ |

Nguồn 5V của FC chịu 2 A liên tục. Tổng tải khoảng 0.5 A (ESP32 ~250 mA khi phát WiFi, GPS ~50 mA, camera ~150 mA, receiver ~50 mA).

Logic UART của Kakute và ESP32 đều là 3.3 V, nối trực tiếp được.

## Thứ tự động cơ (PX4 Quad X)

```
        Mũi (trước)
   M3 (CW)      M1 (CCW)
        \        /
         \      /
          [ FC ]
         /      \
        /        \
   M2 (CCW)     M4 (CW)
```

| Output PX4 | Vị trí | Chiều quay |
| --- | --- | --- |
| Motor 1 | trước-phải | CCW |
| Motor 2 | sau-trái | CCW |
| Motor 3 | trước-trái | CW |
| Motor 4 | sau-phải | CW |

Gán trong QGroundControl → Vehicle Setup → Actuators. **Luôn tháo cánh khi test động cơ.**

## Lắp la bàn

Đặt QMC5883L xa dây nguồn chính và ESC ít nhất 10 cm (tốt nhất trên cột GPS). Mũi tên trên module hướng về mũi drone; nếu lệch, khai báo `CAL_MAG0_ROT` lúc hiệu chỉnh.

## Video FPV (analog 5.8 GHz)

Firmware PX4 cho Kakute H7 Mini **không có driver OSD (AT7456E) và không có driver điều khiển VTX**. Vì vậy nối camera thẳng vào VTX, không đi qua chân VI/VO của FC. Thông tin bay (pin, độ cao, GPS) xem trên QGroundControl qua ESP32, nên không cần OSD.

```
Caddx Ant ──video──► VTX 5.8 GHz ──anten RHCP──► )))  ((( ──► Receiver 5.8 GHz ──USB──► Laptop Ubuntu (QGC)
   ▲ 5V từ FC            ▲ 3S từ PDB
```

Tiêu chí chọn VTX:

- Nguồn vào nhận được 3S (11.1–12.6 V), ví dụ dải 7–26 V; khi đó cấp thẳng từ pin, không tải lên BEC 5 V của FC.
- Công suất chọn được 25 / 200 / 400 mW, có nút bấm và đèn hoặc màn hình để đổi kênh (vì PX4 không điều khiển VTX qua SmartAudio/Tramp).
- Lỗ bắt 20 × 20 mm để xếp tầng cùng Kakute.

**Luôn gắn anten vào VTX trước khi cấp điện**, cấp điện khi chưa có anten sẽ làm cháy tầng phát. Dùng anten RHCP ở cả drone lẫn mặt đất. Trong khu vực thử nghiệm chọn công suất 25–200 mW và tuân thủ quy định tần số tại Việt Nam.

Băng 5.8 GHz không trùng với ELRS và WiFi của ESP32 (cùng ở 2.4 GHz). Nên đặt anten ELRS và anten ESP32 cách nhau ít nhất vài cm, vuông góc nhau.

## Bộ điều khiển RC đề xuất

PX4 tự nhận giao thức CRSF (ELRS) và SBUS trên cổng RC (R6/T6).

| Lựa chọn | Tay điều khiển | Receiver | Giá tham khảo (VND) | Ghi chú |
| --- | --- | --- | --- | --- |
| **Đã chọn** | RadioMaster Pocket ELRS 2.4 GHz | RadioMaster RP1 | ~1.6–2.0 triệu + ~250–350 nghìn | Tầm xa, độ trễ thấp, EdgeTX, cộng đồng lớn; dùng lại được cho dự án khác |
| Rẻ nhất | FlySky FS-i6X | FS-iA6B (SBUS) | ~1.1–1.5 triệu (thường kèm receiver) | Công nghệ cũ hơn nhưng đủ cho đồ án |

Giá thay đổi theo cửa hàng; mua lại đồ cũ trong các nhóm FPV Việt Nam cũng là lựa chọn tốt. Cần tối thiểu 3 công tắc: **kill switch**, chọn chế độ bay, RTL.
