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
      telegram-desktop = { };
      google-chrome = { };

      ffmpeg-full = { };

      losslesscut = { };
    })
  ];
}
