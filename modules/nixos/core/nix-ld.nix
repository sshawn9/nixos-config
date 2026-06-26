{
  lib,
  pkgs,
  ...
}:
{
  programs.nix-ld = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.nix-ld;

    libraries = with pkgs; [
      stdenv.cc.cc.lib

      zlib
      zstd
      openssl
      curl
      libffi
      sqlite

      glib
      dbus

      libGL
      fontconfig
      freetype
      libxkbcommon
      wayland

      libx11
    ];
  };
}
