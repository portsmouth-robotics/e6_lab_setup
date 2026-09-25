# E6 Lab Setup

This repository contains the setup script used to prepare a local Ubuntu account for the DOBOT Magician E6 ROS 2 lab environment.

It is intended for lab/IT setup and recovery, not for student coursework.

> **Do not run the setup script as root.** Run it as the local account that will be used for the E6 lab.

## What the script does

`setup_e6_account.sh`:

- creates the ROS 2 workspace at `~/dobot_ws`;
- creates `~/dobot_ws/src/student_work/` for student repositories;
- clones or updates the Portsmouth Robotics DOBOT ROS 2 driver;
- clones or updates the `e6_lab_support` package;
- creates or restores `~/.bashrc` if it is missing;
- adds the required ROS 2 and DOBOT environment configuration to `~/.bashrc`;
- builds the workspace;
- sources the completed workspace for the current setup session;
- checks that the required ROS packages are available.

The script is intended to be safe to run more than once.

## Prerequisites

The machine should already have:

- Ubuntu;
- ROS 2 Humble installed at `/opt/ros/humble`;
- Git;
- `colcon`;
- network access to GitHub during setup;
- the required network interface configuration for communication with the E6.

The local account does not need to contain an existing DOBOT workspace.

## Running the setup

Clone this repository somewhere outside the ROS workspace, for example:

```bash
cd ~
git clone https://github.com/portsmouth-robotics/e6_lab_setup.git
cd e6_lab_setup
```

Then run:

```bash
./setup_e6_account.sh
```

After setup has completed, open a new terminal so the updated `.bashrc` is loaded.

## Workspace layout

The resulting workspace should look roughly like:

```text
~/dobot_ws/
├── src/
│   ├── DOBOT_6Axis_ROS2_V4/
│   ├── e6_lab_support/
│   └── student_work/
├── build/
├── install/
└── log/
```

Student repositories should be placed under:

```text
~/dobot_ws/src/student_work/
```

## Environment configuration

The setup script adds a managed block to `~/.bashrc`.

This includes:

- sourcing ROS 2 Humble;
- the DOBOT IP address;
- the DOBOT robot type;
- sourcing `~/dobot_ws/install/setup.bash` when available.

The standard E6 lab values are hardcoded because they are intended to be identical across all lab machines:

```bash
export IP_address=192.168.5.1
export DOBOT_TYPE=e6
```

The script updates only its own managed block and does not replace the rest of the user's `.bashrc`.

If `~/.bashrc` does not exist, the script attempts to restore the standard Ubuntu version from:

```text
/etc/skel/.bashrc
```

If that is also unavailable, it creates a new empty `.bashrc` before adding the managed E6 configuration.

## Repositories installed

The script installs or updates:

### DOBOT ROS 2 driver

```text
portsmouth-robotics/DOBOT_6Axis_ROS2_V4
```

Installed at:

```text
~/dobot_ws/src/DOBOT_6Axis_ROS2_V4
```

### E6 lab support

```text
portsmouth-robotics/e6_lab_support
```

Installed at:

```text
~/dobot_ws/src/e6_lab_support
```

## Normal lab startup

After provisioning, the standard E6 startup uses three terminals.

### Terminal 1 — DOBOT driver

```bash
ros2 launch dobot_bringup_v4 dobot_bringup_ros2.launch.py
```

The DOBOT IP address and robot type are already configured in `.bashrc`, so no additional launch arguments are required.

Leave this terminal running.

### Terminal 2 — RViz

```bash
ros2 launch dobot_rviz dobot_rviz.launch.py live_hardware:=true
```

Leave this terminal running.

### Terminal 3 — Robot setup and commands

```bash
ros2 run e6_lab_support robot_setup
```

After that, use Terminal 3 for student packages, commands, or the lab support utilities.

## Lab support tools

The `e6_lab_support` package provides:

```text
robot_setup
pose_monitor
hardware_test
movement_demo
```

These tools are maintained separately from student coursework.

## Re-running the setup script

The setup script may be run again if the account needs to be repaired or refreshed.

When re-run:

- existing lab Git repositories are updated with `git pull --ff-only`;
- the managed `.bashrc` block is replaced cleanly;
- the ROS 2 workspace is rebuilt;
- student repositories under `~/dobot_ws/src/student_work/` are left alone.

If one of the expected repository directories exists but is not a Git repository, the script stops rather than overwriting it.

## Student work

Student repositories should be kept under:

```text
~/dobot_ws/src/student_work/
```

Each group should use a unique ROS 2 package name, for example:

```text
e6_group_01
e6_group_02
```

The student template repository includes a one-time package rename script to avoid duplicate ROS package names.

## Scope

This repository configures the local user environment only.

Machine-level tasks such as:

- installing Ubuntu;
- installing ROS 2 Humble;
- configuring network interfaces;
- installing VS Code;
- applying University IT policies;

are outside the scope of this script.
