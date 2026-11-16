{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      cc = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.stdenv.cc;
      };
      nodejs = lib.mkDefault true;
      rustup = lib.mkDefault true;
      sqlite = lib.mkDefault true;
      gettext = lib.mkDefault true;
      binutils = lib.mkDefault true;
      hyperfine = lib.mkDefault true;
      tokei = lib.mkDefault true;
      watchexec = lib.mkDefault true;
      entr = lib.mkDefault true;
      shellcheck = lib.mkDefault true;
      actionlint = lib.mkDefault true;
      ruff = lib.mkDefault true;
      shfmt = lib.mkDefault true;
      gnumake = lib.mkDefault true;
      pkg-config = lib.mkDefault true;
    };
  };
}
