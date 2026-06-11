[private]
@default:
    just -f "{{ justfile() }}" --list distrobox

# Create a new distrobox container (interactive wizard if no args given)
[group("create")]
create image_name="" container_name="":
    @bash {{ quote(source_directory() / "create-distrobox-container.sh") }} {{ quote(image_name) }} {{ quote(container_name) }}
