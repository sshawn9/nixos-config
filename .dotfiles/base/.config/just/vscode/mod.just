[private]
default:
    @just -f '{{ justfile() }}' --list vscode

# Install VS Code workspace recommended extensions
install-recommended-extensions EXT_FILE=".vscode/extensions.json" CODE_BIN="code":
    @JUST_INVOCATION_DIRECTORY={{ quote(invocation_directory()) }} bash {{ quote(source_directory() / "install-vscode-recommended-extensions.sh") }} {{ quote(EXT_FILE) }} {{ quote(CODE_BIN) }}

# Install VS Code user default recommended extensions
install-default-recommended-extensions CODE_BIN="code":
    @bash {{ quote(source_directory() / "install-vscode-recommended-extensions.sh") }} {{ quote(env_var("HOME") / ".config/Code/User/extensions.json") }} {{ quote(CODE_BIN) }}

# Export currently installed VS Code extensions as workspace recommendations
export-installed-extensions OUT_FILE="extensions.installed.json" CODE_BIN="code":
    @JUST_INVOCATION_DIRECTORY={{ quote(invocation_directory()) }} bash {{ quote(source_directory() / "export-vscode-installed-extensions.sh") }} {{ quote(OUT_FILE) }} {{ quote(CODE_BIN) }}
