# Rice Survey UAV

A quadrotor built on **PX4** and the **Holybro Kakute H7 Mini**, designed to survey rice-seedling density in early growth stages. The drone holds attitude with a cascade PID controller and flies trajectories drawn by the operator, in simulation (PX4 SITL + Gazebo) and on real hardware.

> Graduation project (đồ án tốt nghiệp). Documentation in [`docs/`](docs/) is written in Vietnamese.

## Design targets

| Requirement | Target | Verified by |
| --- | --- | --- |
| Flight time | 12–15 min | `analysis/endurance.py` |
| Attitude error | < 5° | `tests/test_attitude_step.py` |
| Attitude step response | overshoot < 15 %, settling < 2 s | `tests/test_attitude_step.py` |
| Trajectory tracking | RMSE < 0.5 m at 1–2 m/s | `tests/test_tracking.py` |
| Survey area | 50 × 50 m (0.25 ha) at 6 m AGL | `uav_trajectory` coverage planner |

## Architecture

```
 path_studio ──► uav_trajectory ──► uav_offboard (ROS 2, C++) ──► uXRCE-DDS ──► PX4 SITL ◄──► Gazebo
      │                                                                          ▲
      └──► .plan mission ──► QGroundControl ──► ESP32 WiFi bridge ──► Kakute H7 Mini (PX4)
```

- **Simulation:** a ROS 2 offboard node streams position/velocity/acceleration setpoints at 50 Hz.
- **Real flight:** the drawn path becomes a MAVLink mission uploaded over an ESP32 WiFi bridge, so the drone finishes the mission even if the link drops.

See [docs/architecture.md](docs/architecture.md) for details.

## Hardware

| Part | Model |
| --- | --- |
| Flight controller | Holybro Kakute H7 Mini v1.5 (STM32H743, ICM42688P, BMP280) |
| GPS | u-blox NEO-M8N |
| Compass | QMC5883L (I2C) |
| Telemetry | ESP32, MAVLink over WiFi UDP |
| RC link | RadioMaster Pocket ELRS + RadioMaster RP1 (CRSF) |
| Motors / ESC | 4 × 2212 1000 KV, 4 × BLHeli_S 30 A (DShot600) |
| Battery | 3S 4000 mAh LiPo |
| Camera | Caddx Ant (analog) |

Wiring: [docs/wiring.md](docs/wiring.md).

## Software stack

| Component | Version |
| --- | --- |
| PX4-Autopilot | v1.17.0 |
| Ubuntu | 24.04 |
| ROS 2 | Jazzy |
| Gazebo | Harmonic |
| Micro XRCE-DDS Agent | v2.4.3 |
| px4_msgs | `release/1.17` |

## Repository layout

| Path | Contents |
| --- | --- |
| `docs/` | Architecture, wiring, step-by-step guides |
| `firmware/` | PX4 parameter files and custom airframe |
| `simulation/` | Gazebo model, rice-field world, install script |
| `control_design/` | 6-DOF quadrotor model and cascade PID tuning (Python) |
| `ros2_ws/src/` | ROS 2 packages: trajectory library, offboard node, analysis, launch files |
| `tools/path_studio/` | GUI for drawing trajectories |
| `esp32_bridge/` | ESP32 UART ↔ WiFi MAVLink bridge firmware (PlatformIO) |
| `analysis/` | Endurance (flight-time) model |
| `tests/` | SITL integration tests |
| `scripts/` | Environment check and launch helpers |

## Quick start (simulation)

```bash
./scripts/check_env.sh
./scripts/run_sitl.sh
```

## Progress

- [ ] Phase 0 – Repository and development environment
- [ ] Phase 1 – Custom Gazebo model
- [ ] Phase 2 – Dynamics model and cascade PID tuning
- [ ] Phase 3 – Trajectory library and offboard node
- [ ] Phase 4 – Trajectory drawing tool
- [ ] Phase 5 – ESP32 MAVLink bridge
- [ ] Phase 6 – Hardware bring-up
- [ ] Phase 7 – Flight tests
- [ ] Phase 8 – Results and report

## License

BSD 3-Clause, see [LICENSE](LICENSE).
