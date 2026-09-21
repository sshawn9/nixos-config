{
  config,
  lib,
  pkgs,
  ...
}:
let
  sampleInterval = 5;
  retentionDays = 7;
  crashMemory = "1G";
  # Enable only after a maintenance-window crash test has produced a usable dump.
  panicOnHardLockup = false;
  kernel = config.boot.kernelPackages.kernel;
  captureDirectory = "/var/log/freeze-diagnostics";
  crashDirectory = "/var/lib/freeze-diagnostics/crashes";

  capture = pkgs.writeShellApplication {
    name = "freeze-capture";
    runtimeInputs = with pkgs; [
      coreutils
      gdb
      procps
      systemd
      util-linux
    ];
    text = ''
      if [[ $# -gt 1 || ( $# -eq 1 && $1 != --niri-backtrace ) ]]; then
        echo 'Usage: freeze-capture [--niri-backtrace]' >&2
        exit 2
      fi
      if (( EUID != 0 )); then
        echo 'Run freeze-capture as root.' >&2
        exit 1
      fi
      umask 077
      mkdir -p ${captureDirectory}
      exec 9>/run/lock/freeze-capture.lock
      flock --nonblock 9 || exit 1
      destination=$(mktemp -d ${captureDirectory}/capture-"$(date -u +%Y%m%dT%H%M%SZ)"-XXXXXX)
      echo "$destination"

      # Keep the basic snapshot independent of GPU ioctls and graphical services.
      date --iso-8601=ns > "$destination/time.txt"
      uname -a > "$destination/uname.txt"
      cat /proc/cmdline > "$destination/cmdline.txt"
      cat /proc/meminfo > "$destination/meminfo.txt"
      cat /proc/vmstat > "$destination/vmstat.txt"
      for resource in cpu memory io; do
        cat "/proc/pressure/$resource" > "$destination/pressure-$resource.txt"
      done
      timeout --kill-after=2s 5s ps -eLo pid,tid,ppid,user,stat,wchan:40,pcpu,pmem,comm \
        > "$destination/threads.txt" 2>&1 || true
      timeout --kill-after=2s 5s systemctl status scx --no-pager \
        > "$destination/scx.txt" 2>&1 || true
      timeout --kill-after=2s 10s journalctl -b --since '-5 minutes' --no-pager \
        > "$destination/journal.txt" 2>&1 || true

      # Explicitly requested only: attaching a debugger briefly pauses niri.
      if [[ ''${1-} == --niri-backtrace ]]; then
        for pid in $(pgrep -x niri || true); do
          timeout --kill-after=2s 10s gdb --nx --batch \
            -iex 'set auto-load off' -iex 'set debuginfod enabled off' \
            -ex 'thread apply all bt' -ex detach --pid "$pid" \
            > "$destination/niri-$pid.txt" 2>&1 || true
        done
      fi

      # SysRq writes kernel stacks to the kernel log; none of these keys reboot.
      for key in w l m; do
        printf '%s' "$key" > /proc/sysrq-trigger
      done
      timeout --kill-after=2s 10s journalctl --sync || true
      timeout --kill-after=2s 5s journalctl -k -b -n 4000 --no-pager \
        > "$destination/kernel.txt" 2>&1 || true
      sync -f "$destination"
    '';
  };

  saveCrash = pkgs.writeShellApplication {
    name = "freeze-save-crash";
    runtimeInputs = with pkgs; [
      coreutils
      kexec-tools
      zstd
    ];
    text = ''
      # Also guard the executable itself: it must never dump a normal boot.
      test -r /proc/vmcore
      umask 077
      mkdir -p ${crashDirectory}
      destination=$(mktemp -d ${crashDirectory}/"$(date -u +%Y%m%dT%H%M%SZ)"-XXXXXX)
      echo "Saving crash evidence to $destination; do not power off."

      # Save the small original-kernel log even if there is insufficient dump space.
      vmcore-dmesg /proc/vmcore > "$destination/dmesg.txt" || true
      cp /proc/cmdline "$destination/capture-kernel-cmdline.txt"
      cp ${kernel.configfile} "$destination/kernel.config"
      printf '%s\n' '${kernel.dev}/vmlinux' > "$destination/vmlinux-source.txt"
      sync -f "$destination"

      # Reserve enough for the worst case: compression is not guaranteed to help.
      # Leave 2 GiB free and retain previous dumps instead of deleting evidence.
      available=$(df --output=avail -B1 "$destination" | tail -n 1)
      required=$(( $(stat -c %s /proc/vmcore) + $(stat -c %s ${kernel.dev}/vmlinux) + 2147483648 ))
      if (( available < required )); then
        echo 'Insufficient space for a complete crash dump; dmesg was saved.' >&2
        exit 1
      fi

      # Copy symbols so a later Nix garbage collection cannot orphan the dump.
      cp --reflink=auto ${kernel.dev}/vmlinux "$destination/vmlinux"
      # This nixpkgs has no makedumpfile; retain a lossless, compressed ELF vmcore.
      zstd -T1 -1 /proc/vmcore -o "$destination/vmcore.zst.partial"
      mv "$destination/vmcore.zst.partial" "$destination/vmcore.zst"
      sync -f "$destination"
      touch "$destination/complete"
      sync -f "$destination"
      echo "Crash dump complete: $destination. Remaining in rescue mode."
    '';
  };
in
{
  assertions = [
    {
      assertion = !config.boot.crashDump.enable;
      message = "freeze-diagnostics owns kdump loading; do not also enable boot.crashDump.";
    }
  ];

  boot = {
    kernel.sysctl = {
      "kernel.watchdog" = 1;
      # Override the host's performance-oriented setting in cachyos-kernel.nix.
      "kernel.nmi_watchdog" = lib.mkForce 1;
      "kernel.watchdog_thresh" = 10;
      # The loader may arm panic only after kexec confirms a capture kernel is ready.
      "kernel.hardlockup_panic" = 0;
      "kernel.hardlockup_all_cpu_backtrace" = 1;
      "kernel.softlockup_panic" = 0;
      "kernel.softlockup_all_cpu_backtrace" = 1;
      "kernel.hung_task_timeout_secs" = 30;
      "kernel.hung_task_check_interval_secs" = 10;
      "kernel.hung_task_panic" = 0;
      "kernel.hung_task_warnings" = -1;
      # Debugging dumps (8) and filesystem sync (16); retains Alt+SysRq+w/l/m/s.
      "kernel.sysrq" = 24;
    };

    kernelParams = [
      "crashkernel=${crashMemory}"
      "nmi_watchdog=nopanic,1"
      "softlockup_panic=0"
    ];
  };

  services.journald.settings.Journal = {
    Storage = "persistent";
    SyncIntervalSec = "5s";
    SystemMaxUse = "2G";
    SystemKeepFree = "2G";
    MaxRetentionSec = "14day";
  };

  programs.atop = {
    enable = true;
    atopService.enable = true;
    atopRotateTimer.enable = true;
    atopacctService.enable = true;
    # GPU collection is isolated below, so a stalled NVML call cannot block atop.
    atopgpu.enable = false;
  };
  environment = {
    systemPackages = [ capture ];
    etc = {
      # atoprc.interval only controls interactive use; the recorder reads this file.
      "default/atop".text = ''
        LOGINTERVAL=${toString sampleInterval}
        LOGGENERATIONS=${toString retentionDays}
        LOGPATH=/var/log/atop
      '';
      "freeze-diagnostics/README".text = ''
        本机卡死取证

        atop: /var/log/atop/atop_YYYYMMDD，每 ${toString sampleInterval} 秒采样，约保留 ${toString retentionDays} 天。
        回看: sudo atop -r /var/log/atop/atop_YYYYMMDD -b HH:MM:SS
        GPU: journalctl -b -1 -u freeze-gpu.service
        手动快照: sudo freeze-capture（写入 ${captureDirectory}）
        需要 niri 用户态调用栈时加 --niri-backtrace；调试器附加时会暂时暂停 niri。
        桌面失效时可依次尝试 Alt+SysRq+w、l、m、s；画面未更新不代表没有输出。
        记下状态栏最后显示的秒数，用来对齐采样和内核日志。

        kdump 需要重启使 crashkernel=${crashMemory} 生效；不是仅切换配置就能启用。
        预加载状态: systemctl status freeze-kdump-load; cat /sys/kernel/kexec_crash_loaded
        只有在保存工作后的维护窗口，才手动验证 panic 和转储；本模块不会主动触发测试。
        自动 hardlockup panic 当前为 ${lib.boolToString panicOnHardLockup}，验证后才修改模块中的开关并重启。
        即使打开该开关，也只会在崩溃内核成功预加载后启用自动 panic。
        转储存放在 ${crashDirectory}，complete 文件表示写入完成。
        转储期间不要断电；完成或失败后都停留在救援模式，不自动重启。
        vmcore.zst 是完整内存映像，可能含敏感数据；目录只允许 root 访问。
        解压后的 vmcore 可配合同目录 vmlinux 分析；不自动删除崩溃证据。
        日志、SysRq 和 kdump 均不能保证捕获固件或硬件层面的彻底锁死。
      '';
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d ${captureDirectory} 0700 root root -"
      "d ${crashDirectory} 0700 root root -"
      # Keep this inode across failed GPU services, including unkillable D-state tasks.
      "f /run/lock/freeze-gpu.lock 0600 root root -"
    ];

    services = {
      atop.serviceConfig = {
        LogsDirectory = "atop";
        LogsDirectoryMode = "0700";
        UMask = "0077";
      };

      freeze-atop-sync = {
        description = "Flush recent atop samples to local storage";
        serviceConfig = {
          Type = "oneshot";
          # A stuck fsync stays in this one unit; the timer will not start another.
          TimeoutStartSec = "infinity";
        };
        path = [ pkgs.coreutils ];
        script = ''
          logfile="/var/log/atop/atop_$(date +%Y%m%d)"
          if [ -f "$logfile" ]; then
            sync -d "$logfile"
          fi
        '';
      };

      freeze-gpu = {
        description = "Record NVIDIA state independently of CPU and process sampling";
        after = [ "systemd-tmpfiles-setup.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.util-linux}/bin/flock --nonblock --conflict-exit-code=75 /run/lock/freeze-gpu.lock"
            "${config.hardware.nvidia.package}/bin/nvidia-smi"
            "--query-gpu=timestamp,index,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,pstate"
            "--format=csv,noheader,nounits"
          ];
          TimeoutStartSec = "5s";
          TimeoutStopSec = "2s";
          KillMode = "control-group";
          SuccessExitStatus = [ 75 ];
          CPUWeight = 10;
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      # The upstream crashDump module enables automatic panic and only enters rescue.
      # Load from the booted generation, guard against recursion, and save locally.
      freeze-kdump-load = {
        description = "Preload a crash capture kernel without triggering a crash";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        restartIfChanged = false;
        unitConfig = {
          ConditionPathExists = "!/proc/vmcore";
          ConditionKernelCommandLine = "crashkernel=${crashMemory}";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.coreutils ];
        script = ''
          booted=$(readlink -f /run/booted-system)
          ${pkgs.kexec-tools}/bin/kexec -p "$booted/kernel" \
            --initrd="$booted/initrd" \
            --command-line="init=$booted/init root=${config.fileSystems."/".device} rootfstype=${config.fileSystems."/".fsType} irqpoll nr_cpus=1 reset_devices nomodeset module_blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm,nouveau systemd.unit=rescue.target sysctl.kernel.nmi_watchdog=0 sysctl.kernel.hardlockup_panic=0 sysctl.kernel.softlockup_panic=0"
          test "$(cat /sys/kernel/kexec_crash_loaded)" = 1
        ''
        + lib.optionalString panicOnHardLockup ''
          printf '1\n' > /proc/sys/kernel/hardlockup_panic
        '';
      };

      freeze-save-crash = {
        description = "Save original kernel log, symbols and vmcore to local disk";
        wantedBy = [ "rescue.target" ];
        before = [ "rescue.service" ];
        after = [ "local-fs.target" ];
        unitConfig = {
          ConditionPathExists = "/proc/vmcore";
          RequiresMountsFor = [ crashDirectory ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe saveCrash;
          TimeoutStartSec = "infinity";
          UMask = "0077";
          StandardOutput = "journal+console";
          StandardError = "journal+console";
        };
      };
    };

    timers = lib.genAttrs [ "freeze-atop-sync" "freeze-gpu" ] (_: {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitInactiveSec = "${toString sampleInterval}s";
        AccuracySec = "1s";
      };
    });
  };
}
