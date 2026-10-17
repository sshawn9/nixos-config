{
  config,
  lib,
  ...
}:
{
  xdg.configFile."just" = lib.mkIf config.my.packages.just.enable (
    config.my.paths.local.xdgConfigLayeredTree "just"
  );

  my.packages = {
    wget = lib.mkDefault true;
    sshpass = lib.mkDefault true;
    age = lib.mkDefault true;
    lsof = lib.mkDefault true;
    # net-tools, including netstat
    nettools = lib.mkDefault true;
    gdu = lib.mkDefault true;
    duf = lib.mkDefault true;
    bc = lib.mkDefault true;
    file = lib.mkDefault true;
    tree = lib.mkDefault true;
    gettext = lib.mkDefault true;
    libarchive = lib.mkDefault true;
    moreutils = lib.mkDefault true;
    pv = lib.mkDefault true;
    dos2unix = lib.mkDefault true;
    lz4 = lib.mkDefault true;
    brotli = lib.mkDefault true;
    p7zip = lib.mkDefault true;
    openssl = lib.mkDefault true;
    unzip = lib.mkDefault true;
    zip = lib.mkDefault true;
    socat = lib.mkDefault true;
    whois = lib.mkDefault true;
    nmap = lib.mkDefault true;
    binutils = lib.mkDefault true;
    hyperfine = lib.mkDefault true;
    tokei = lib.mkDefault true;
    watchexec = lib.mkDefault true;
    entr = lib.mkDefault true;
    libxml2 = lib.mkDefault true;
    xmlstarlet = lib.mkDefault true;
    qpdf = lib.mkDefault true;
    poppler-utils = lib.mkDefault true;
    imagemagick = lib.mkDefault true;
    exiftool = lib.mkDefault true;
    dnsutils = lib.mkDefault true;
    shellcheck = lib.mkDefault true;
    actionlint = lib.mkDefault true;
    ruff = lib.mkDefault true;
    shfmt = lib.mkDefault true;
    gnumake = lib.mkDefault true;
    just = lib.mkDefault true;
    pkg-config = lib.mkDefault true;
    witr = lib.mkDefault true;
    yq = lib.mkDefault true;
    miller = lib.mkDefault true;
    jo = lib.mkDefault true;
    dasel = lib.mkDefault true;
    sd = lib.mkDefault true;
    ncdu = lib.mkDefault true;
    dust = lib.mkDefault true;
    procs = lib.mkDefault true;
    xh = lib.mkDefault true;
    ssh-to-age = lib.mkDefault true;
    sops = lib.mkDefault true;
    easytier = lib.mkDefault true;
  };
}
