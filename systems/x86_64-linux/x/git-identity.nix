{
  config,
  ...
}:
let
  inherit (config.my.shared) username;
in
{
  home-manager = {
    users.${username} = {
      programs.git = {
        settings.user = {
          name = "sshawn9";
          email = "29659937+sshawn9@users.noreply.github.com";
        };

        # TODO: Store the Gitee PAT in sops, add a credential helper to this include,
        # then strip the embedded credentials from the ~/ghq/gitee.com remotes.
        includes = [
          {
            condition = "gitdir:~/ghq/gitee.com/";
            contents.user = {
              name = "sshawn9";
              email = "regiprotonregi@protonmail.com";
            };
          }
        ];
      };
    };
  };
}
