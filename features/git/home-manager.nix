{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  catppuccin = {
    lazygit.enable = lib.mkDefault config.programs.lazygit.enable;
    delta.enable = lib.mkDefault config.programs.delta.enable;
  };

  programs = {
    git = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.git;
      lfs = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.git-lfs;
      };
      settings = {
        init.defaultBranch = lib.mkDefault "main";
        pull.rebase = lib.mkDefault true;
        rebase.autoStash = lib.mkDefault true;
        push.autoSetupRemote = lib.mkDefault true;
        core.quotepath = lib.mkDefault false;
      };
    };

    gh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.gh;
      settings.git_protocol = lib.mkDefault "https";
      gitCredentialHelper.enable = lib.mkDefault config.programs.git.enable;
      extensions = [ pkgs.unstable.gh-markdown-preview ];
    };

    mr = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.mr;
    };

    lazygit = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.lazygit;
    };

    delta = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.delta;
      enableGitIntegration = lib.mkDefault config.programs.git.enable;
      options = {
        navigate = lib.mkDefault true;
        line-numbers = lib.mkDefault true;
        side-by-side = lib.mkDefault true;
      };
    };
  };

  package = {
    ghq = lib.mkDefault true;
    gfold = lib.mkDefault true;
    gita = lib.mkDefault true;
  };
}
