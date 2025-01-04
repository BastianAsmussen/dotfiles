{lib, ...}: {
  security = {
    auditd.enable = true;
    audit = {
      enable = true;
      backlogLimit = 8192;
      failureMode = "printk";
      rules = [
        "-a exit,always -F arch=b64 -F euid=0 -S execve"
        "-a exit,always -F arch=b32 -F euid=0 -S execve"
        "-a exit,always -F arch=b64 -F euid=0 -S execveat"
        "-a exit,always -F arch=b32 -F euid=0 -S execveat"

        # Protect logfile.
        "-w /var/log/audit/ -k auditlog"

        # Log program executions.
        "-a exit,always -F arch=b64 -S execve -F key=progexec"

        # Home path access/modification.
        "-a always,exit -F arch=b64 -F dir=/home -F perm=war -F key=homeaccess"

        # Kexec attempts.
        "-a always,exit -F arch=b64 -S kexec_load -F key=KEXEC"
        "-a always,exit -F arch=b32 -S sys_kexec_load -k KEXEC"

        # Unauthorized file access.
        "-a always,exit -F arch=b64 -S open,creat -F exit=-EACCES -k access"
        "-a always,exit -F arch=b64 -S open,creat -F exit=-EPERM -k access"
        "-a always,exit -F arch=b32 -S open,creat -F exit=-EACCES -k access"
        "-a always,exit -F arch=b32 -S open,creat -F exit=-EPERM -k access"
        "-a always,exit -F arch=b64 -S openat -F exit=-EACCES -k access"
        "-a always,exit -F arch=b64 -S openat -F exit=-EPERM -k access"
        "-a always,exit -F arch=b32 -S openat -F exit=-EACCES -k access"
        "-a always,exit -F arch=b32 -S openat -F exit=-EPERM -k access"
        "-a always,exit -F arch=b64 -S open_by_handle_at -F exit=-EACCES -k access"
        "-a always,exit -F arch=b64 -S open_by_handle_at -F exit=-EPERM -k access"
        "-a always,exit -F arch=b32 -S open_by_handle_at -F exit=-EACCES -k access"
        "-a always,exit -F arch=b32 -S open_by_handle_at -F exit=-EPERM -k access"

        # Failed modification of important mountpoints or files.
        "-a always,exit -F arch=b64 -S open -F dir=/etc -F success=0 -F key=unauthedfileaccess"
        "-a always,exit -F arch=b64 -S open -F dir=/bin -F success=0 -F key=unauthedfileaccess"
        "-a always,exit -F arch=b64 -S open -F dir=/var -F success=0 -F key=unauthedfileaccess"
        "-a always,exit -F arch=b64 -S open -F dir=/home -F success=0 -F key=unauthedfileaccess"
        "-a always,exit -F arch=b64 -S open -F dir=/srv -F success=0 -F key=unauthedfileaccess"
        "-a always,exit -F arch=b64 -S open -F dir=/boot -F success=0 -F key=unauthedfileaccess"
        "-a always,exit -F arch=b64 -S open -F dir=/nix -F success=0 -F key=unauthedfileaccess"

        # File deletions by system users.
        "-a always,exit -F arch=b64 -S rmdir -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -F key=delete"

        # Root command executions.
        "-a always,exit -F arch=b64 -F euid=0 -F auid>=1000 -F auid!=-1 -S execve -F key=rootcmd"

        # Shared memory access.
        "-a exit,never -F arch=b32 -F dir=/dev/shm -k sharedmemaccess"
        "-a exit,never -F arch=b64 -F dir=/dev/shm -k sharedmemaccess"
      ];
    };
  };

  systemd = {
    # A systemd timer to clean /var/log/audit.log daily this can probably be
    # weekly, but daily means we get to clean it every 2-3 days instead of once
    # a week.
    timers."clean-audit-log" = {
      description = "Periodically clean audit log";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # Clean audit log if it's more than 512 MiB. It can grow very large in size
    # if left unchecked.
    services."clean-audit-log" = {
      script = ''
        set -eu

        if [[ $(stat -c "%s" /var/log/audit/audit.log) -gt ${toString (lib.custom.units.mibToBytes 512)} ]]; then
          echo "Clearing Audit Log...";
          rm -rfv /var/log/audit/audit.log;

          echo "Done!"
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
