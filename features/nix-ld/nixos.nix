{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.nix-ld.enable {
    programs.nix-ld = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.nix-ld;
      libraries = with pkgs.unstable; [
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
        vulkan-loader
        libx11
      ];
    };
  };
}
