{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.ssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.openssh;
    };

    programs = {
      mosh = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.mosh;
      };
    };

    package = {
      tsshd.enable = true;
      trzsz-ssh.enable = true;
    };

    networking.firewall.allowedUDPPortRanges = [
      {
        from = 61001;
        to = 61999;
      }
    ];
  };
}
