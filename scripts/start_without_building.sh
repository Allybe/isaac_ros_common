#!/bin/bash
ISAAC_ROS_DEV_DIR="$1"
if [[ -z "$ISAAC_ROS_DEV_DIR" ]]; then
    ISAAC_ROS_DEV_DIR="$HOME/workspaces/isaac_ros-dev"
    if [[ ! -d "$ISAAC_ROS_DEV_DIR" ]]; then
        ISAAC_ROS_DEV_DIR=$(pwd)
    fi
    print_warning "isaac_ros_dev not specified, assuming $ISAAC_ROS_DEV_DIR"
else
    shift 1
fi

PLATFORM="$(uname -m)"

BASE_NAME="isaac_ros_dev-$PLATFORM"
CONTAINER_NAME="$BASE_NAME-container"

# Remove any exited containers.
if [ "$(docker ps -a --quiet --filter status=exited --filter name=$CONTAINER_NAME)" ]; then
    docker rm $CONTAINER_NAME > /dev/null
fi

# Re-use existing container.
if [ "$(docker ps -a --quiet --filter status=running --filter name=$CONTAINER_NAME)" ]; then
    print_info "Attaching to running container: $CONTAINER_NAME"
    docker exec -i -t -u admin --workdir /workspaces/isaac_ros-dev $CONTAINER_NAME /bin/bash $@
    exit 0
fi

DOCKER_ARGS+=("-v /tmp/.X11-unix:/tmp/.X11-unix")
DOCKER_ARGS+=("-e DISPLAY")
DOCKER_ARGS+=("-e NVIDIA_VISIBLE_DEVICES=all")
DOCKER_ARGS+=("-e NVIDIA_DRIVER_CAPABILITIES=all")

DOCKER_ARGS+=("-v /usr/bin/tegrastats:/usr/bin/tegrastats")
DOCKER_ARGS+=("-v /tmp/argus_socket:/tmp/argus_socket")
DOCKER_ARGS+=("-v /usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/tegra")
DOCKER_ARGS+=("-v /usr/src/jetson_multimedia_api:/usr/src/jetson_multimedia_api")
DOCKER_ARGS+=("-v /opt/nvidia/nsight-systems-cli:/opt/nvidia/nsight-systems-cli")
DOCKER_ARGS+=("-v /usr/local/cuda-10.2/targets/aarch64-linux/lib/:/usr/local/cuda-10.2/targets/aarch64-linux/lib/")
DOCKER_ARGS+=("--pid=host")

print_info "Running $CONTAINER_NAME"
docker run -it --rm \
    --privileged --network host \
    ${DOCKER_ARGS[@]} \
    -v $ISAAC_ROS_DEV_DIR:/workspaces/isaac_ros-dev \
    -v /dev/shm:/dev/shm \
    --name "$CONTAINER_NAME" \
    --runtime nvidia \
    --user="admin" \
    --entrypoint /usr/local/bin/scripts/workspace-entrypoint.sh \
    --workdir /workspaces/isaac_ros-dev \
    $@ \
    $BASE_NAME \
    /bin/bash

