{
  config,
  lib,
  pkgs,
  ...
}:

{
  xdg.configFile."yazi/yazi.toml" = lib.mkIf config.programs.yazi.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "yazi/yazi.toml";
  };
  xdg.configFile."htop/htoprc" = lib.mkIf config.programs.htop.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "htop/htoprc";
  };

  programs = {
    direnv = {
      package = lib.mkDefault pkgs.unstable.direnv;
      enable = lib.mkDefault true;
      nix-direnv.enable = lib.mkDefault true;
    };

    vim = {
      enable = lib.mkDefault true;
    };

    htop = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.htop;
    };

    btop = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.btop;
    };

    fastfetch = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.fastfetch;
    };

    bat = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.bat;
    };

    ripgrep = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.ripgrep;
    };

    ripgrep-all = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.ripgrep-all;
    };

    fd = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.fd;
    };

    eza = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.eza;
      git = true;
    };

    yazi = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.yazi;
      shellWrapperName = "y";
    };

    jq = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.jq;
    };
  };
}
