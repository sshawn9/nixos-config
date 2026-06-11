{
  pkgs,
  ...
}:

pkgs.writeShellApplication {
  name = "mihomo-switch";

  runtimeInputs = with pkgs; [
    curl
    coreutils
  ];

  text = builtins.readFile ./switch.sh;
}
