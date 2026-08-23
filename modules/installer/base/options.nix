{
  lib,
  self,
  config,
  system,
  name,
  ...
}:
{
  options.my.installer.offline.enable =
    lib.mkEnableOption "refusing every remote source while installing"
    // {
      default = true;
    };

  options.my.installer.source = lib.mkOption {
    type = lib.types.path;
    default = lib.cleanSource self.outPath;
    defaultText = lib.literalExpression "lib.cleanSource self.outPath";
    description = ''
      Configuration flake that the medium copies to the installed system.

      A path flake may carry `.git`. Excluding VCS metadata ensures that the
      copied `/etc/nixos` is evaluated as a path flake and therefore includes
      the files the installer generates next to it.
    '';
  };

  options.my.installer.image = lib.mkOption {
    type = lib.types.package;
    default = config.system.build.isoImage;
    defaultText = lib.literalExpression "config.system.build.isoImage";
    description = ''
      Build product published as `packages.<system>.<name>`.

      An installer that is not an ISO, such as a netboot or SD card image,
      overrides this with its own build attribute.
    '';
  };

  options.my.installer.target = lib.mkOption {
    type = lib.types.str;

    # A medium usually installs the host it is named after. Overriding is the
    # normal case as soon as one target has several media.
    default = "${name}@${system}";

    example = "installer-target";

    # Both `<host>` and `<host>@<platform>` are accepted. The platform half is
    # already fixed by the medium's own directory under installers/, so it is
    # filled in when omitted and rejected when it disagrees: a medium can only
    # install a host of its own platform.
    #
    # Naming something that is not under installer-systems/ fails here, with the
    # list of what is, rather than as a missing attribute from somewhere deeper.
    apply =
      value:
      let
        declaredSystem = lib.tail (lib.splitString "@" value);

        qualified =
          if declaredSystem == [ ] then
            "${value}@${system}"
          else if declaredSystem == [ system ] then
            value
          else
            throw "my.installer.target is \"${value}\", but a medium under installers/${system}/ can only install a host of that platform; write the host directory name alone, or suffix it with @${system}";
      in
      if self.installedSystems ? ${qualified} then
        qualified
      else
        throw "my.installer.target is \"${qualified}\", which is not under installer-systems/; the tree holds ${lib.concatStringsSep ", " (lib.attrNames self.installedSystems)}";

    description = ''
      Host under installer-systems/<this platform>/ that the medium installs,
      written as the host directory name, optionally suffixed with this
      platform. Reading the option always yields the `<directory>@<platform>`
      key of `self.installedSystems`, which is the composition the medium
      prebuilds and the generated flake calls.
    '';
  };
}
