{
  pkgs,
  config,
  ...
}:
let
  inherit (config.my.shared) username;
in
{
  home-manager = {
    users.${username} = {
      programs = {
        htop.package = pkgs.unstable.htop.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            ./patches/htop-nvidia-nvml-fallback.patch
          ];

          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
            pkgs.unstable.makeWrapper
          ];

          postFixup = (oldAttrs.postFixup or "") + ''
            wrapProgram $out/bin/htop \
              --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
          '';
        });
      };
    };
  };
}
