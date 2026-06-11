{
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      google-chrome = { };
      antigravity = { };
      code-cursor = { };
      github-desktop = { };
      sqlite = { };
      sqlitebrowser = { };

      rustup = { };

      inshellisense = { };

      telegram-desktop = { };

      warp-terminal = { };

      ssh-to-age = {
        enable = true;
      };
      sops = {
        enable = true;
      };
    })
  ];
}
