{ lib, ... }:

{
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_MESSAGES = lib.mkDefault "en_US.UTF-8";
      LC_MEASUREMENT = lib.mkDefault "zh_CN.UTF-8";
      LC_PAPER = lib.mkDefault "zh_CN.UTF-8";
    };
  };
}
