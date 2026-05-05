{
  flake.nixosModules.security = {pkgs, ...}: {
    boot = {
      kernel.sysctl = {
        # Allow only safe SysRq functions (keyboard/console control for REISUB).
        "kernel.sysrq" = 4;

        ## Kernel info leaks.
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;

        ## Disable unprivileged eBPF and userfaultfd.
        "kernel.unprivileged_bpf_disabled" = 1;
        "vm.unprivileged_userfaultfd" = 0;

        ## Filesystem hardening.
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;

        ## TCP hardening.
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_rfc1337" = 1;

        ## TCP optimization.
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "cake";
      };

      kernelModules = ["tcp_bbr"];
      blacklistedKernelModules = [
        # Unused network protocols.
        "dccp"
        "sctp"
        "rds"
        "tipc"
        "can"
        "atm"
        "ipx"

        # Unused filesystems.
        "cramfs"
        "jffs2"
        "hfs"
      ];
    };

    security = {
      apparmor = {
        enable = true;
        enableCache = true;
        killUnconfinedConfinables = true;
        packages = [pkgs.apparmor-profiles];
      };

      protectKernelImage = true;
      forcePageTableIsolation = true;
      unprivilegedUsernsClone = false;
      polkit.enable = true;
      rtkit.enable = true;
      sudo.enable = false;
      sudo-rs.enable = true;

      # Always flush L1 cache before entering a guest.
      virtualisation.flushL1DataCache = "always";
    };

    systemd.coredump.enable = false;
    services.dbus.implementation = "broker";
  };
}
