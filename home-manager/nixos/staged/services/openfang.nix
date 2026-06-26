{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:

let
  cfg = config.my.services.openfang;

  upstreamPackage = inputs.openfang.packages.${system}.default;

  patchedPackage = upstreamPackage.overrideAttrs (old: {
    # openfang-cli-deps uses strictDeps, so perl must be in nativeBuildInputs
    # rather than only buildInputs for openssl-src's Configure step.
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.perl ];

    cargoArtifacts = old.cargoArtifacts.overrideAttrs (depsOld: {
      nativeBuildInputs = (depsOld.nativeBuildInputs or [ ]) ++ [ pkgs.perl ];
    });
  });

  tomlFormat = pkgs.formats.toml { };

  mcpServerList = lib.mapAttrsToList (name: server: { inherit name; } // server) (
    config.programs.mcp.servers or { }
  );

  settings = {
    default_model = cfg.defaultModel;
    memory.decay_rate = 0.05;
    network.listen_addr = "127.0.0.1:${toString cfg.port}";
  }
  // lib.optionalAttrs (mcpServerList != [ ]) {
    mcp_servers = mcpServerList;
  }
  // cfg.extraSettings;

  configFile = tomlFormat.generate "openfang-config.toml" settings;
in
{
  options.my.services.openfang = {
    enable = lib.mkEnableOption "OpenFang Agent OS daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = patchedPackage;
      defaultText = lib.literalExpression "patchedPackage";
      description = "OpenFang CLI package providing the `openfang` binary.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4200;
      description = "Local OFP / dashboard port.";
    };

    defaultModel = lib.mkOption {
      inherit (tomlFormat) type;
      default = {
        provider = "ollama";
        model = "qwen3.5:9b";
        base_url = "http://127.0.0.1:11434";
      };
      description = ''
        Default LLM provider for OpenFang. Defaults to the local Ollama
        backend declared in modules/nixos/services/ollama.nix.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional EnvironmentFile for the systemd user service, used to inject
        API keys (e.g. ANTHROPIC_API_KEY) without writing them to the Nix store.
        Typically wired to a sops-nix decrypted secret path.
      '';
    };

    extraSettings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "Extra keys merged into ~/.openfang/config.toml.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".openfang/config.toml".source = configFile;

    systemd.user.services.openfang = {
      Unit = {
        Description = "OpenFang Agent OS daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe' cfg.package "openfang"} start";
        Restart = "on-failure";
        RestartSec = 5;
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
