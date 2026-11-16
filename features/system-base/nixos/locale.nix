{ config, lib, ... }:
{
  config = lib.mkIf config.features.system-base.enable {
    time.timeZone = lib.mkDefault "Asia/Shanghai";

    i18n = {
      defaultLocale = lib.mkDefault "en_US.UTF-8";
      extraLocaleSettings = {
        LC_MEASUREMENT = lib.mkDefault "zh_CN.UTF-8";
        LC_PAPER = lib.mkDefault "zh_CN.UTF-8";
      };
    };
  };
}
