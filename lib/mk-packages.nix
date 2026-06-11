{ lib, ... }:
let
  # Package catalog shape
  # Scope:   internal
  # Returns: documentation-only convention for package catalog entries
  # Use:     shared vocabulary for the helpers below
  # Notes:   a non-empty attrset without these keys is treated as a group;
  #          an empty attrset is treated as a package leaf resolved by path.
  #          Catalog keys are option defaults, not final config values; users
  #          can still override the generated options later.
  # Example:
  #   {
  #     ripgrep = { };
  #     fd = { enable = true; description = "fd"; };
  #     custom-tool = { package = pkgs.custom-tool; };
  #     nvtopPackages.full = { };
  #   }
  #
  #   Produces options:
  #     my.home.package.ripgrep.enable
  #     my.home.package.ripgrep.package
  #     my.home.package.fd.enable
  #     my.home.package.fd.package
  #     my.home.package.custom-tool.enable
  #     my.home.package.custom-tool.package
  #     my.home.package.nvtopPackages.full.enable
  #     my.home.package.nvtopPackages.full.package
  packageNodeKeys = [
    "description"
    "enable"
    "package"
  ];

  # defaultPackageSet
  # Scope:   internal
  # Returns: package set used for path-based package resolution
  # Use:     keep package declarations short when package is not specified
  # Notes:   prefers pkgs.unstable when the overlay provides it; falls back
  #          to pkgs for standalone home-manager or hosts without unstable
  # Example:
  #   defaultPackageSet pkgs
  #   => pkgs.unstable or pkgs
  defaultPackageSet = pkgs: pkgs.unstable or pkgs;

  # packageSetResolver
  # Scope:   lib
  # Returns: resolver function from package path to derivation
  # Use:     resolve empty package leaves from a package set
  # Notes:   this is the bridge between the option tree and pkgs.
  #
  #          In the package catalog, an empty attrset means:
  #
  #            "Use this option path to find the package with the same path
  #             inside the selected package set."
  #
  #          For example:
  #
  #            {
  #              ripgrep = { };
  #              nvtopPackages.full = { };
  #            }
  #
  #          The generated option paths are:
  #
  #            my.home.package.ripgrep.enable
  #            my.home.package.nvtopPackages.full.enable
  #
  #          Internally, those package names become Nix path lists:
  #
  #            [ "ripgrep" ]
  #            [ "nvtopPackages" "full" ]
  #
  #          packageSetResolver turns those path lists into real package
  #          lookups against a package set such as pkgs or pkgs.unstable:
  #
  #            [ "ripgrep" ]                  => packageSet.ripgrep
  #            [ "nvtopPackages" "full" ]     => packageSet.nvtopPackages.full
  #
  #          Missing packages fail when their option is enabled. This is
  #          intentional: a typo like ripgrepp = { }; should be visible
  #          instead of silently producing no installed package.
  #
  #          Use an explicit package when the option name should not match
  #          the package path or when a different default should be offered:
  #
  #            my-tool = { package = pkgs.somewhere.real-package; };
  # Example:
  #   resolver = packageSetResolver pkgs;
  #   resolver [ "ripgrep" ]
  #   => pkgs.ripgrep
  #
  #   resolver [ "nvtopPackages" "full" ]
  #   => pkgs.nvtopPackages.full
  packageSetResolver = packageSet: path: lib.getAttrFromPath path packageSet;

  # isPackageNode
  # Scope:   internal
  # Returns: true when a catalog node is a package leaf
  # Use:     distinguish package leaves from nested option groups
  # Notes:   derivations, empty attrsets, and attrsets containing package
  #          metadata keys are leaves; other attrsets are groups
  # Example:
  #   isPackageNode { }
  #   => true
  #
  #   isPackageNode { enable = true; }
  #   => true
  #
  #   isPackageNode { package = pkgs.fd; }
  #   => true
  #
  #   isPackageNode pkgs.ripgrep
  #   => true
  #
  #   isPackageNode { nvtopPackages.full = { }; }
  #   => false
  isPackageNode =
    node:
    lib.isDerivation node
    || (
      builtins.isAttrs node
      && !lib.isDerivation node
      && (node == { } || builtins.any (key: builtins.hasAttr key node) packageNodeKeys)
    );

  # packageNodeDescription
  # Scope:   internal
  # Returns: option description for a package leaf
  # Use:     feed lib.mkEnableOption with useful text
  # Notes:   description is optional; without it, the dotted package path is used
  # Example:
  #   packageNodeDescription [ "ripgrep" ] { }
  #   => "ripgrep"
  #
  #   packageNodeDescription [ "fd" ] { description = "fd file finder"; }
  #   => "fd file finder"
  packageNodeDescription =
    path: node:
    if builtins.isAttrs node && builtins.hasAttr "description" node then
      node.description
    else
      builtins.concatStringsSep "." path;

  # packageNodeDefaultEnable
  # Scope:   internal
  # Returns: generated enable option default for a package leaf
  # Use:     keep enable default handling consistent for attrset leaves and
  #          direct derivation leaves
  # Notes:   derivation leaves default to disabled; attrset leaves can set
  #          enable = true to generate an enabled-by-default option
  # Example:
  #   packageNodeDefaultEnable { }
  #   => false
  #
  #   packageNodeDefaultEnable { enable = true; }
  #   => true
  #
  #   packageNodeDefaultEnable pkgs.ripgrep
  #   => false
  packageNodeDefaultEnable = node: if lib.isDerivation node then false else node.enable or false;

  # packageNodeDefaultPackage
  # Scope:   internal
  # Returns: generated package option default for a package leaf
  # Use:     turn catalog package defaults into overridable package options
  # Notes:   direct derivation leaves win first, explicit package defaults win
  #          second, and empty leaves resolve from the package path
  # Example:
  #   packageNodeDefaultPackage resolver [ "ripgrep" ] { }
  #   => resolver [ "ripgrep" ]
  #
  #   packageNodeDefaultPackage resolver [ "custom-tool" ] {
  #     package = pkgs.custom-tool;
  #   }
  #   => pkgs.custom-tool
  #
  #   packageNodeDefaultPackage resolver [ "fd" ] pkgs.fd
  #   => pkgs.fd
  packageNodeDefaultPackage =
    resolver: path: node:
    if lib.isDerivation node then node else node.package or (resolver path);

  # mkPackageOptions
  # Scope:   lib
  # Returns: option tree matching the package catalog shape
  # Use:     generate enable and package options for every package leaf
  # Notes:   group attrsets preserve their structure; leaves receive only an
  #          enable option and a package option. The catalog values are
  #          defaults; the generated config can override them.
  # Example:
  #   mkPackageOptions resolver { ripgrep = { }; fd.enable = true; }
  #   => {
  #        ripgrep.enable = <option default false>;
  #        ripgrep.package = <option default resolver [ "ripgrep" ]>;
  #        fd.enable = <option default true>;
  #        fd.package = <option default resolver [ "fd" ]>;
  #      }
  mkPackageOptions =
    resolver: packages:
    let
      go =
        path: node:
        if isPackageNode node then
          {
            enable = lib.mkEnableOption (packageNodeDescription path node) // {
              default = packageNodeDefaultEnable node;
            };

            package = lib.mkOption {
              type = lib.types.package;
              default = packageNodeDefaultPackage resolver path node;
              description = "Package installed when ${builtins.concatStringsSep "." path} is enabled.";
            };
          }
        else
          lib.mapAttrs (childName: childNode: go (path ++ [ childName ]) childNode) node;
    in
    lib.mapAttrs (name: node: go [ name ] node) packages;

  # collectEnabledPackages
  # Scope:   lib
  # Returns: flat list of derivations enabled in the generated option tree
  # Use:     feed home.packages or environment.systemPackages
  # Notes:   package resolution stays behind currentCfg.package, so disabled
  #          unresolved leaves do not fail; enabled missing packages fail when
  #          the generated package option is used
  # Example:
  #   collectEnabledPackages {
  #     cfg.ripgrep.enable = true;
  #     cfg.ripgrep.package = pkgs.ripgrep;
  #     packages.ripgrep = { };
  #   }
  #   => [ pkgs.ripgrep ]
  collectEnabledPackages =
    {
      cfg,
      packages,
    }:
    let
      go =
        currentCfg: path: node:
        if isPackageNode node then
          lib.optional (currentCfg.enable or false) currentCfg.package
        else
          builtins.concatLists (
            lib.mapAttrsToList (
              childName: childNode: go (currentCfg.${childName} or { }) (path ++ [ childName ]) childNode
            ) node
          );
    in
    builtins.concatLists (
      lib.mapAttrsToList (name: node: go (cfg.${name} or { }) [ name ] node) packages
    );

  # mkPackageModule
  # Scope:   internal
  # Returns: module that defines package enable options and installs packages
  # Use:     shared implementation for mkHomePackages and mkSystemPackages
  # Notes:   targetPath is intentionally used only by the two public wrappers;
  #          this helper keeps the implementation small without turning the
  #          public API into a general package-target framework
  # Example:
  #   mkPackageModule {
  #     namespace = [ "my" "home" "package" ];
  #     targetPath = [ "home" "packages" ];
  #     resolver = packageSetResolver pkgs;
  #     packages = { ripgrep = { }; };
  #   }
  #   => module defining my.home.package.ripgrep.enable,
  #      my.home.package.ripgrep.package, and writing enabled packages to
  #      home.packages
  mkPackageModule =
    {
      namespace,
      targetPath,
      resolver,
      packages,
    }:
    { config, ... }:
    let
      cfg = lib.attrByPath namespace { } config;
      enabledPackages = collectEnabledPackages {
        inherit cfg packages;
      };
    in
    {
      options = lib.setAttrByPath namespace (mkPackageOptions resolver packages);

      config = lib.setAttrByPath targetPath enabledPackages;
    };

  # mkHomePackages
  # Scope:   home-manager
  # Returns: Home Manager module
  # Use:     generate my.home.package.*.enable options and install enabled
  #          packages into home.packages
  # Notes:   path-based leaves resolve from pkgs.unstable or pkgs. Use
  #          { package = ...; } when the package name/path differs from pkgs
  #          or when the generated package option needs a different default.
  # Example:
  #   imports = [
  #     (mkHomePackages {
  #       ripgrep = { enable = true; };
  #       nvtopPackages.full = { };
  #       custom-tool = { package = pkgs.custom-tool; };
  #     })
  #   ];
  #
  #   my.home.package.nvtopPackages.full.enable = true;
  #   => home.packages contains pkgs.unstable.nvtopPackages.full or
  #      pkgs.nvtopPackages.full
  mkHomePackages =
    packages:
    {
      pkgs,
      ...
    }@moduleArgs:
    let
      resolver = packageSetResolver (defaultPackageSet pkgs);

      innerModule = mkPackageModule {
        namespace = [
          "my"
          "packages"
        ];
        targetPath = [
          "home"
          "packages"
        ];
        inherit resolver packages;
      };
    in
    innerModule moduleArgs;

  # mkSystemPackages
  # Scope:   nixos | darwin
  # Returns: NixOS/nix-darwin module
  # Use:     generate my.system.package.*.enable options and install enabled
  #          packages into environment.systemPackages
  # Notes:   this is the system-level counterpart to mkHomePackages; keep
  #          program/service configuration in native modules instead
  # Example:
  #   imports = [
  #     (mkSystemPackages {
  #       btrfs-progs = { enable = true; };
  #       smartmontools = { };
  #     })
  #   ];
  #
  #   my.system.package.smartmontools.enable = true;
  #   => environment.systemPackages contains pkgs.unstable.smartmontools or
  #      pkgs.smartmontools
  mkSystemPackages =
    packages:
    {
      pkgs,
      ...
    }@moduleArgs:
    let
      resolver = packageSetResolver (defaultPackageSet pkgs);

      innerModule = mkPackageModule {
        namespace = [
          "my"
          "packages"
        ];
        targetPath = [
          "environment"
          "systemPackages"
        ];
        inherit resolver packages;
      };
    in
    innerModule moduleArgs;
in
{
  inherit
    mkHomePackages
    mkSystemPackages
    ;
}
