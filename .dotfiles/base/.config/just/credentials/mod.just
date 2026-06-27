[private]
default:
    @just -f '{{ justfile() }}' --list credentials

# Check Cloudflare API token, zone access, and account discovery
[group("check")]
cloudflare TOKEN:
    @bash {{ quote(source_directory() / "check-cloudflare.sh") }} {{ quote(TOKEN) }}

# Check GitHub API token and discover accessible repositories
[group("check")]
github TOKEN DEEP="":
    @bash {{ quote(source_directory() / "check-github.sh") }} {{ quote(TOKEN) }} {{ quote(DEEP) }}

# Check Gitee API token and discover accessible repositories
[group("check")]
gitee TOKEN DEEP="":
    @bash {{ quote(source_directory() / "check-gitee.sh") }} {{ quote(TOKEN) }} {{ quote(DEEP) }}
