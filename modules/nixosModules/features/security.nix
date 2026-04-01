{
  flake.nixosModules.security = {pkgs, ...}: {
    # Kernel hardening.
    boot = {
      kernel.sysctl = {
        # Disable Magic SysRq key.
        "kernel.sysrq" = 0;

        ## TCP Hardening
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

        ## TCP Optimization
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "cake";

        ## Kernel pointer and dmesg restrictions.
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;

        ## Disable unprivileged user namespaces (reduces attack surface).
        "kernel.unprivileged_userns_clone" = 0;

        ## Restrict ptrace to direct child processes only.
        "kernel.yama.ptrace_scope" = 1;

        ## Disable core dumps.
        "fs.suid_dumpable" = 0;
      };

      kernelModules = ["tcp_bbr"];

      # Kernel parameters for additional hardening.
      kernelParams = [
        "slab_nomerge"
        "init_on_alloc=1"
        "init_on_free=1"
        "page_alloc.shuffle=1"
        "randomize_kstack_offset=on"
      ];
    };

    # Security hardening
    security = {
      apparmor = {
        enable = true;

        enableCache = true;
        killUnconfinedConfinables = true;
        packages = [pkgs.apparmor-profiles];
      };

      protectKernelImage = true;
      lockKernelModules = false;
      forcePageTableIsolation = true;
      polkit.enable = true;
      rtkit.enable = true;

      sudo.enable = false;
      sudo-rs.enable = true;

      # Always flush L1 cache before entering a guest.
      virtualisation.flushL1DataCache = "always";
    };

    # Enable the firewall with a deny-all-inbound default.
    networking.firewall = {
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
    };

    # Harden systemd services.
    systemd.coredump.extraConfig = ''
      Storage=none
      ProcessSizeMax=0
    '';
  };
}
