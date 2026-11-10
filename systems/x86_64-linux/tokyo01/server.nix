_:

{
  # Keep shared modules and their general-purpose defaults. Override only
  # features enabled by the repository that this headless cloud host does not use.
  services = {
    pipewire = {
      enable = false;
      wireplumber.enable = false;
    };
    gnome.at-spi2-core.enable = false;
    gnome.gnome-keyring.enable = false;
    upower.enable = false;
    udisks2.enable = false;
    gvfs.enable = false;
    power-profiles-daemon.enable = false;

    avahi.enable = false;
    mihomo.enable = false;

    # Exporters have independent switches and are enabled by the shared module
    # even when the Prometheus server itself is disabled.
    prometheus.exporters = {
      node.enable = false;
      blackbox.enable = false;
      smartctl.enable = false;
      process.enable = false;
      snmp.enable = false;
    };
  };

  security = {
    rtkit.enable = false;
  };

  hardware = {
    bluetooth.enable = false;
    i2c.enable = false;
  };
}
