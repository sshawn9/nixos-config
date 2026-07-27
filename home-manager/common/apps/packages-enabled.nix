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
      ffmpeg-full = {
        enable = true;
      };
    })
  ];
}
