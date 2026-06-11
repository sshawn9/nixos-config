{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    uv = {
      enable = lib.mkDefault false;
      package = pkgs.unstable.uv;

      settings = {
        python-preference = "only-managed";
        python-downloads = "automatic";

        index = [
          {
            name = "tuna";
            url = "https://pypi.tuna.tsinghua.edu.cn/simple";
          }
          {
            name = "pypi";
            url = "https://pypi.org/simple";
            default = true;
          }
        ];
        index-strategy = "first-index";
      };
    };
  };
}
