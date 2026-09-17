{
  flake.nixosModules.schizofoxDev =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      inherit (config.preferences.user) name;
      inherit (lib) getExe';

      devDir = "/run/schizofox-dev";
      devMount = "${utils.escapeSystemdPath devDir}.mount";

      fidoNode = pkgs.writeShellScript "schizofox-fido-node" ''
        set -eu

        case "$1" in
          add)
            ${getExe' pkgs.coreutils "mknod"} -m 0600 "${devDir}/$2" c "$3" "$4"
            ${getExe' pkgs.coreutils "chown"} ${name} "${devDir}/$2"
            ;;
          remove)
            ${getExe' pkgs.coreutils "rm"} -f "${devDir}/$2"
            ;;
        esac
      '';
    in
    {
      fileSystems.${devDir} = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "nosuid"
          "mode=0755"
          "uid=${toString config.users.users.${name}.uid}"
          "gid=${toString config.users.groups.${name}.gid}"
        ];
      };

      systemd = {
        tmpfiles.rules = [
          "c ${devDir}/null 0666 root root - 1:3"
          "c ${devDir}/zero 0666 root root - 1:5"
          "c ${devDir}/full 0666 root root - 1:7"
          "c ${devDir}/random 0666 root root - 1:8"
          "c ${devDir}/urandom 0666 root root - 1:9"
          "c ${devDir}/tty 0666 root root - 5:0"
          "d ${devDir}/pts 0755 root root -"
          "d ${devDir}/shm 1777 root root -"
          "L ${devDir}/fd - - - - /proc/self/fd"
          "L ${devDir}/stdin - - - - /proc/self/fd/0"
          "L ${devDir}/stdout - - - - /proc/self/fd/1"
          "L ${devDir}/stderr - - - - /proc/self/fd/2"
          "L ${devDir}/ptmx - - - - pts/ptmx"
          "L ${devDir}/core - - - - /proc/kcore"
        ];

        services.schizofox-dev = {
          bindsTo = [ devMount ];
          partOf = [ devMount ];
          after = [ devMount ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = [
              "${getExe' pkgs.systemd "systemd-tmpfiles"} --create --prefix=${devDir}"
              "${getExe' pkgs.systemd "udevadm"} trigger --subsystem-match=hidraw --action=add"
            ];
          };
        };
      };

      services.udev.extraRules = ''
        SUBSYSTEM=="hidraw", ACTION=="add", ENV{ID_FIDO_TOKEN}=="1", RUN+="${fidoNode} add %k %M %m"
        SUBSYSTEM=="hidraw", ACTION=="remove", RUN+="${fidoNode} remove %k"
      '';
    };
}
