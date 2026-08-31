{
  config,
  lib,
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      wget = {
        enable = true;
      };
      sshpass = {
        enable = true;
      };
      age = {
        enable = true;
      };
      lsof = {
        enable = true;
      };
      nettools = {
        enable = true;
        description = "net-tools, including netstat";
      };
      apx = {
        enable = true;
      };
      gdu = {
        enable = true;
      };
      duf = {
        enable = true;
      };
      bc = {
        enable = true;
      };
      file = {
        enable = true;
      };
      tree = {
        enable = true;
      };
      gettext = {
        enable = true;
      };
      libarchive = {
        enable = true;
      };
      moreutils = {
        enable = true;
      };
      pv = {
        enable = true;
      };
      dos2unix = {
        enable = true;
      };
      lz4 = {
        enable = true;
      };
      brotli = {
        enable = true;
      };
      p7zip = {
        enable = true;
      };
      openssl = {
        enable = true;
      };
      unzip = {
        enable = true;
      };
      zip = {
        enable = true;
      };
      socat = {
        enable = true;
      };
      whois = {
        enable = true;
      };
      nmap = {
        enable = true;
      };
      binutils = {
        enable = true;
      };
      hyperfine = {
        enable = true;
      };
      tokei = {
        enable = true;
      };
      watchexec = {
        enable = true;
      };
      entr = {
        enable = true;
      };
      libxml2 = {
        enable = true;
      };
      xmlstarlet = {
        enable = true;
      };
      qpdf = {
        enable = true;
      };
      poppler-utils = {
        enable = true;
      };
      imagemagick = {
        enable = true;
      };
      exiftool = {
        enable = true;
      };
      dnsutils = {
        enable = true;
      };
      shellcheck = {
        enable = true;
      };
      shfmt = {
        enable = true;
      };
      gnumake = {
        enable = true;
      };
      just = {
        enable = true;
      };
      pkg-config = {
        enable = true;
      };
      witr = {
        enable = true;
      };
      yq = {
        enable = true;
      };
      miller = {
        enable = true;
      };
      jo = {
        enable = true;
      };
      dasel = {
        enable = true;
      };
      sd = {
        enable = true;
      };
      ncdu = {
        enable = true;
      };
      dust = {
        enable = true;
      };
      procs = {
        enable = true;
      };
      xh = {
        enable = true;
      };
      ssh-to-age = {
        enable = true;
      };
      sops = {
        enable = true;
      };
    })
  ];

  xdg.configFile."just" = lib.mkIf config.my.packages.just.enable (
    config.my.paths.local.xdgConfigLayeredTree "just"
  );
}
