{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    git = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.git;
      lfs.enable = lib.mkDefault true;

      settings = {
        user = {
          name = "sshawn9";
          email = "29659937+sshawn9@users.noreply.github.com";
        };

        init.defaultBranch = "main";

        pull.rebase = true;
        rebase.autoStash = true;
        # fetch.prune = true;
        # rerere.enabled = true;
        # merge.conflictStyle = "zdiff3";
        push.autoSetupRemote = true;
        core.quotepath = false;
      };
    };

    gh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.gh;

      settings = {
        git_protocol = "https";
      };

      extensions = with pkgs; [ gh-markdown-preview ];
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

      enableGitIntegration = true;

      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };
  };
}
