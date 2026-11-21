{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabledBackends = lib.filterAttrs (_: backend: backend.enable) (
    lib.getAttrs [ "udp" "tcp" "ws" ] config.features.easytier.backend
  );
  databaseDirectory = "/var/lib/easytier-geoip";
  databaseFile = "${databaseDirectory}/GeoLite2-City.mmdb";
  backendServices = map (name: "easytier-web-${name}.service") (builtins.attrNames enabledBackends);
in
{
  config = lib.mkIf (config.features.easytier.enable && enabledBackends != { }) {
    systemd.services =
      lib.mapAttrs' (name: _: {
        name = "easytier-web-${name}";
        value = {
          environment.ET_GEOIP_DB = databaseFile;
          requires = [ "easytier-geoip-update.service" ];
          after = [ "easytier-geoip-update.service" ];
        };
      }) enabledBackends
      // {
        easytier-geoip-update = {
          description = "Update the EasyTier Web GeoLite2 City database";
          # oneshot 不保留 active 状态；系统启动和每次配置应用时均重新检查。
          wantedBy = [
            "multi-user.target"
            "sysinit-reactivation.target"
          ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          path = [
            pkgs.unstable.curl
            pkgs.unstable.libmaxminddb
          ];
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "easytier-geoip";
            StateDirectoryMode = "0755";
          };
          script = ''
            temporaryDirectory=$(mktemp -d ${databaseDirectory}/.update.XXXXXX)
            trap 'rm -rf "$temporaryDirectory"' EXIT

            # 没有数据库时不能发送旧 ETag，否则 304 响应无法完成首次下载。
            if [ ! -s ${databaseFile} ]; then
              rm -f ${databaseDirectory}/etag
            fi

            if status=$(curl --fail --silent --show-error --location \
              --retry 3 --connect-timeout 15 --max-time 300 \
              --etag-compare ${databaseDirectory}/etag \
              --etag-save "$temporaryDirectory/etag" \
              --output "$temporaryDirectory/GeoLite2-City.mmdb" \
              --write-out '%{http_code}' \
              https://raw.githubusercontent.com/P3TERX/GeoLite.mmdb/download/GeoLite2-City.mmdb); then
              if [ "$status" = 304 ]; then
                exit 0
              fi

              # 先确认数据库可读取；下载或校验失败时保留现有数据库。
              if mmdblookup --file "$temporaryDirectory/GeoLite2-City.mmdb" \
                --ip 8.8.8.8 country iso_code > /dev/null; then
                if cmp -s "$temporaryDirectory/GeoLite2-City.mmdb" ${databaseFile}; then
                  mv "$temporaryDirectory/etag" ${databaseDirectory}/etag
                  exit 0
                fi

                chmod 0644 "$temporaryDirectory/GeoLite2-City.mmdb"
                mv "$temporaryDirectory/GeoLite2-City.mmdb" ${databaseFile}
                mv "$temporaryDirectory/etag" ${databaseDirectory}/etag
                # 后端启动也等待本服务；异步提交重启，避免互相等待。
                systemctl --no-block try-restart ${lib.escapeShellArgs backendServices}
                exit 0
              fi
            fi

            echo "GeoLite2 City update failed; reusing the existing database if available." >&2
            test -s ${databaseFile}
          '';
        };
      };

    systemd.timers.easytier-geoip-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
