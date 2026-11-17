# Show carla.sh usage
[private]
default:
    @bash {{ quote(source_directory() / "carla.sh") }}

# Run CARLA in Docker with my default settings
docker-default *args="":
    bash {{ quote(source_directory() / "carla.sh") }} docker 0.9.15 -nosound -quality-level=Low {{ args }}
