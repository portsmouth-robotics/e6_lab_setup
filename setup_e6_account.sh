#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------------------------
# DOBOT E6 ROS 2 lab account setup
#
# Run this script as the local student/lab account, NOT as root.
#
# It:
#   - creates ~/dobot_ws
#   - creates ~/dobot_ws/src/student_work
#   - clones or updates the DOBOT ROS 2 driver
#   - clones or updates the E6 lab support package
#   - creates/restores ~/.bashrc if needed
#   - adds the required ROS/DOBOT environment to ~/.bashrc
#   - builds the workspace
#   - verifies that the required ROS packages are available
#
# The script is intended to be safe to run more than once.
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Safety check
# ---------------------------------------------------------------------------

if [ "${EUID}" -eq 0 ]; then
    echo "ERROR: Do not run this script as root."
    echo "Run it as the local account that will be used for the E6 lab."
    exit 1
fi


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

WORKSPACE="$HOME/dobot_ws"
SRC_DIR="$WORKSPACE/src"
STUDENT_DIR="$SRC_DIR/student_work"

DOBOT_REPO="https://github.com/portsmouth-robotics/DOBOT_6Axis_ROS2_V4.git"
DOBOT_DIR="$SRC_DIR/DOBOT_6Axis_ROS2_V4"

LAB_SUPPORT_REPO="https://github.com/portsmouth-robotics/e6_lab_support.git"
LAB_SUPPORT_DIR="$SRC_DIR/e6_lab_support"

ROS_SETUP="/opt/ros/humble/setup.bash"

DOBOT_IP="192.168.5.1"
DOBOT_TYPE="e6"


# ---------------------------------------------------------------------------
# Helper function: clone a repo if missing, otherwise update it
# ---------------------------------------------------------------------------

update_repo() {
    local repo_url="$1"
    local repo_dir="$2"
    local repo_name="$3"

    if [ -d "$repo_dir/.git" ]; then
        echo
        echo "Updating $repo_name..."
        git -C "$repo_dir" pull --ff-only
    elif [ -e "$repo_dir" ]; then
        echo
        echo "ERROR: $repo_dir exists but is not a Git repository."
        echo "Please move or remove it, then run this script again."
        exit 1
    else
        echo
        echo "Cloning $repo_name..."
        git clone "$repo_url" "$repo_dir"
    fi
}


# ---------------------------------------------------------------------------
# Check prerequisites
# ---------------------------------------------------------------------------

echo "Checking prerequisites..."

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is not installed or not available in PATH."
    exit 1
fi

if ! command -v colcon >/dev/null 2>&1; then
    echo "ERROR: colcon is not installed or not available in PATH."
    exit 1
fi

if [ ! -f "$ROS_SETUP" ]; then
    echo "ERROR: ROS 2 Humble was not found at:"
    echo "  $ROS_SETUP"
    exit 1
fi


# ---------------------------------------------------------------------------
# Create workspace structure
# ---------------------------------------------------------------------------

echo
echo "Creating workspace directories..."

mkdir -p "$SRC_DIR"
mkdir -p "$STUDENT_DIR"


# ---------------------------------------------------------------------------
# Clone/update lab-maintained repositories
# ---------------------------------------------------------------------------

update_repo \
    "$DOBOT_REPO" \
    "$DOBOT_DIR" \
    "DOBOT ROS 2 driver"

update_repo \
    "$LAB_SUPPORT_REPO" \
    "$LAB_SUPPORT_DIR" \
    "E6 lab support"


# ---------------------------------------------------------------------------
# Create or restore ~/.bashrc if needed
# ---------------------------------------------------------------------------

echo
echo "Configuring ~/.bashrc..."

BASHRC="$HOME/.bashrc"

if [ ! -f "$BASHRC" ]; then
    echo "No ~/.bashrc found."

    if [ -f /etc/skel/.bashrc ]; then
        echo "Restoring the default Ubuntu ~/.bashrc from /etc/skel/.bashrc..."
        cp /etc/skel/.bashrc "$BASHRC"
    else
        echo "No /etc/skel/.bashrc found - creating an empty ~/.bashrc."
        touch "$BASHRC"
    fi
fi


# ---------------------------------------------------------------------------
# Add/update the managed E6 environment block
# ---------------------------------------------------------------------------

BEGIN_MARKER="# >>> Portsmouth Robotics E6 setup >>>"
END_MARKER="# <<< Portsmouth Robotics E6 setup <<<"

# Remove any existing managed block so rerunning the script updates it cleanly.
sed -i \
    "/^${BEGIN_MARKER//\//\\/}$/,/^${END_MARKER//\//\\/}$/d" \
    "$BASHRC"

cat >> "$BASHRC" <<EOF

$BEGIN_MARKER

# ROS 2 Humble
source /opt/ros/humble/setup.bash

# DOBOT Magician E6 connection settings - standard across all machines
export IP_address=192.168.5.1
export DOBOT_TYPE=me6

# Source the local DOBOT workspace if it has been built.
if [ -f "\$HOME/dobot_ws/install/setup.bash" ]; then
    source "\$HOME/dobot_ws/install/setup.bash"
fi

$END_MARKER
EOF


# ---------------------------------------------------------------------------
# Build workspace
# ---------------------------------------------------------------------------

echo
echo "Building ROS 2 workspace..."

source "$ROS_SETUP"

cd "$WORKSPACE"

colcon build \
    --allow-overriding dobot_msgs_v4


# Source the newly built workspace for this script's shell.
source "$WORKSPACE/install/setup.bash"


# ---------------------------------------------------------------------------
# Basic verification
# ---------------------------------------------------------------------------

echo
echo "Checking installed packages..."

if ! ros2 pkg prefix dobot_bringup_v4 >/dev/null 2>&1; then
    echo "ERROR: dobot_bringup_v4 was not found after the build."
    exit 1
fi

if ! ros2 pkg prefix e6_lab_support >/dev/null 2>&1; then
    echo "ERROR: e6_lab_support was not found after the build."
    exit 1
fi


# ---------------------------------------------------------------------------
# Finished
# ---------------------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "DOBOT E6 lab setup complete."
echo "------------------------------------------------------------"
echo
echo "Workspace:"
echo "  $WORKSPACE"
echo
echo "Student repositories should be placed in:"
echo "  $STUDENT_DIR"
echo
echo "Open a new terminal before using the ROS environment."
echo
echo "Normal startup:"
echo
echo "  Terminal 1:"
echo "    ros2 launch dobot_bringup_v4 dobot_bringup_ros2.launch.py"
echo
echo "  Terminal 2:"
echo "    ros2 launch dobot_rviz dobot_rviz.launch.py live_hardware:=true"
echo
echo "  Terminal 3:"
echo "    ros2 run e6_lab_support robot_setup"
echo
