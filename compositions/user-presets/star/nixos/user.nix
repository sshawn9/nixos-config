{
  config,
  self,
  lib,
  ...
}:
let
  inherit (config.common) primaryUser;
in
{
  # common.primaryUser 由 HM 转发给系统，须先明确 HM 用户和转发源。
  # 这里若使用 config.common.primaryUser，会依赖尚待确定的 HM 配置，形成循环。
  home-manager.users.star.imports = [ self.homeModules.star ];
  sharedOptionsUser = "star";

  users.users.${primaryUser} = {
    isNormalUser = lib.mkDefault true;
    extraGroups = [ "wheel" ];
    password = lib.mkIf (!config.features.sops.enable) "nixos";
    hashedPasswordFile = lib.mkIf config.features.sops.enable config.sops.secrets.starHashedPassword.path;
  };

  sops.secrets.starHashedPassword = lib.mkIf config.features.sops.enable {
    sopsFile = self.outPath + "/secrets/star/hashed-password.enc.yaml";
    key = "hashed_password";
    neededForUsers = true;
  };
}
