{ pkgs, inputs, ... }:

{
  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation (final: {
      name = "brcm-firmware";
      src = inputs.a2141-brcm-firmware;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        cp -r ${final.src}/firmware/brcm/* "$out/lib/firmware/brcm"
      '';
    }))
  ];
  hardware.enableRedistributableFirmware = true;
}
