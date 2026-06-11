[private]
default:
    @just -f '{{ justfile() }}' --list docker

# Create a new Docker container (interactive wizard if no args given)
[group("create")]
create image_name='' container_name='' cmd='':
    @bash {{ quote(source_directory() / "create-docker-container.sh") }} {{ quote(image_name) }} {{ quote(container_name) }} {{ quote(cmd) }}

# List images across all independent container stores (Docker, Podman, etc.)
[group("inventory")]
images:
    @bash {{ quote(source_directory() / "list-container-images.sh") }}

# List containers across all independent container stores (Docker, Podman, etc.)
[group("inventory")]
containers:
    @bash {{ quote(source_directory() / "list-containers.sh") }}

# Pull latest version of every tagged image across all container stores
[group("maintenance")]
update-images:
    @bash {{ quote(source_directory() / "update-container-images.sh") }}

# Run a temporary ROS Humble container with GPU and display passthrough
[group("runtime")]
tmp-humble:
    docker run -it --rm \
      --privileged \
      --ipc host \
      --network host \
      --device=nvidia.com/gpu=all \
      -e NVIDIA_DRIVER_CAPABILITIES=all \
      -e DISPLAY=$DISPLAY \
      -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
      -v /etc/localtime:/etc/localtime:ro \
      -v /dev/input:/dev/input \
      -v ~:/home/$USER \
      sshawn/humble-desktop \
      bash
