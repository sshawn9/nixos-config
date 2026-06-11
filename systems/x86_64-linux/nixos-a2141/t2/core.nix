{ inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.apple-t2
  ];

  boot = {
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "pcie_ports=compat" # or native if thunderbolt not working well
      # "i915.enable_guc=2" # or 2 if not working well
      # "module_blacklist=amdgpu,radeon" # disable amdgpu
      "initcall_blacklist=simpledrm_platform_driver_init" # kill the ghost display
    ];
    # blacklistedKernelModules = [ "amdgpu" "radeon" ]; # disable amdgpu
    kernelModules = [ "apple-bce" ];
    extraModprobeConfig = ''
      options apple-gmux force_igd=y
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="ac:de:48:00:11:22", NAME="t2_ncm"
  '';

  networking = {
    networkmanager = {
      settings = {
        main.no-auto-default = "t2_ncm";
      };
      wifi.backend = "iwd";
    };
    wireless.iwd.enable = true;
  };
}
