{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  normalConf = ./profiles/normal.conf;
  silenceConf = ./profiles/silence.conf;
  turboConf = ./profiles/turbo.conf;

  t2fan-profile = pkgs.writeShellScriptBin "t2fan-profile" ''
    set -euo pipefail
    p="''${1:-}" 
    case "$p" in
      normal|silence|turbo) ;;
      *)
        echo "Usage: t2fan-profile normal|silence|turbo" >&2
        exit 2
        ;;
    esac

    ln -sf "/etc/t2fanrd/profiles/$p.conf" /etc/t2fand.conf
    systemctl restart t2fanrd.service
  '';
in
{
  imports = [
    inputs.t2fanrd.nixosModules.t2fanrd
  ];

  services.t2fanrd.enable = true;

  environment = {
    etc = {
      "t2fanrd/profiles/normal.conf".source = normalConf;
      "t2fanrd/profiles/silence.conf".source = silenceConf;
      "t2fanrd/profiles/turbo.conf".source = turboConf;
      "t2fand.conf".source = lib.mkForce normalConf;
    };
    systemPackages = [ t2fan-profile ];
  };
}
