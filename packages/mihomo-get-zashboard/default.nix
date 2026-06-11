{
  pkgs,
  ...
}:

pkgs.writeShellApplication {
  name = "mihomo-get-zashboard";

  runtimeInputs = with pkgs; [
    curl
    unzip
    coreutils
  ];

  text = builtins.readFile ./get-zashboard.sh;
}
