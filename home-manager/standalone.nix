{
  lib,
  myLib,
  system,
  username,
  ...
}:
let
  platform = lib.systems.elaborate system;
  inherit (platform) isLinux isDarwin;

  rootHome = if isDarwin then "/var/root" else "/root";
  userHome = if isDarwin then "/Users/${username}" else "/home/${username}";
  defaultHomeDirectory = if username == "root" then rootHome else userHome;
in
{
  imports =
    (myLib.loadRecursiveModulePathList ./common)
    ++ lib.optionals isLinux (myLib.loadRecursiveModulePathList ./nixos)
    ++ lib.optionals isDarwin (myLib.loadRecursiveModulePathList ./darwin);

  home = {
    username = lib.mkDefault username;
    homeDirectory = lib.mkDefault defaultHomeDirectory;
  };

  programs.home-manager.enable = true;
}
