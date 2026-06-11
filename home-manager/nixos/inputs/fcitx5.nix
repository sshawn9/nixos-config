{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.my.paths.local)
    xdgConfigLayeredSource
    xdgDataLayeredSource
    ;

  rimeSyncDir = "${config.home.homeDirectory}/ghq/github.com/sshawn9/rime-sync";
in
{
  xdg = {
    configFile = {
      "fcitx5/config".source = xdgConfigLayeredSource "fcitx5/config";
      "fcitx5/profile".source = xdgConfigLayeredSource "fcitx5/profile";
      "fcitx5/conf/classicui.conf".source = xdgConfigLayeredSource "fcitx5/conf/classicui.conf";
      "fcitx5/conf/rime.conf".source = xdgConfigLayeredSource "fcitx5/conf/rime.conf";
    };

    dataFile = {
      "fcitx5/rime/default.custom.yaml".source = xdgDataLayeredSource "fcitx5/rime/default.custom.yaml";
      "fcitx5/rime/rime_ice.custom.yaml".source = xdgDataLayeredSource "fcitx5/rime/rime_ice.custom.yaml";
      "fcitx5/rime/fcitx5.custom.yaml".source = xdgDataLayeredSource "fcitx5/rime/fcitx5.custom.yaml";
    };
  };

  home.activation.patchRimeInstallation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rime_dir="$HOME/.local/share/fcitx5/rime"
    installation="$rime_dir/installation.yaml"

    install -d "$rime_dir"
    install -d "${rimeSyncDir}"
    test -e "$installation" || install -m 600 /dev/null "$installation"

    tmp="$(mktemp)"
    cp "$installation" "$tmp"

    ${pkgs.yq-go}/bin/yq -i '
      .installation_id = "star-nixos-rime-sync" |
      .sync_dir = "${rimeSyncDir}"
    ' "$tmp"

    if ! cmp -s "$tmp" "$installation"; then
      cp "$tmp" "$installation"
    fi

    rm -f "$tmp"
  '';
}
