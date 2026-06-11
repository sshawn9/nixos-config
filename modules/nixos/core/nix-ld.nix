{
  pkgs,
  ...
}:
{
  programs.nix-ld = {
    enable = true;
    package = pkgs.unstable.nix-ld;

    # libraries = with pkgs; [];
  };
}
