_:

{
  nix.settings = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://sshawn9.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "sshawn9.cachix.org-1:RHYGWuav56oECYgrMMsnyOn3t2sbLQVIr4dEZ4H5J5k="
    ];
  };
}
