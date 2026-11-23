{ modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-gnome.nix")
  ];

  features = {
    installer = {
      enable = true;
      target = ./target;
      offline.enable = true;
    };
    # Use the upstream Live defaults for SSH and base system settings.
    ssh.enable = false;
    system-base.enable = false;
  };

  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.shell]
    welcome-dialog-last-shown-version='9999999999'
    [org.gnome.desktop.session]
    idle-delay=0
    [org.gnome.settings-daemon.plugins.power]
    sleep-inactive-ac-type='nothing'
    sleep-inactive-battery-type='nothing'
  '';
  services.desktopManager.gnome.extraGSettingsOverridePackages = [ pkgs.gnome-settings-daemon ];
}
