{
  config,
  lib,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.libvirt.enable {
    package = {
      virt-manager = lib.mkDefault true;
      freerdp = lib.mkDefault true;
    };

    dconf.settings = lib.mkIf config.package.virt-manager.enable {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = lib.mkDefault [ "qemu:///system" ];
        uris = lib.mkDefault [ "qemu:///system" ];
      };
    };
  };
}
