{
  flake.nixosModules.security = {pkgs, ...}: {
    # Kernel hardening.
    boot = {
      kernel.sysctl = {
        # Allow only safe SysRq functions (keyboard/console control for REISUB).
        "kernel.sysrq" = 4;

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
      };

      kernelModules = ["tcp_bbr"];
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
      forcePageTableIsolation = true;
      polkit.enable = true;
      rtkit.enable = true;

      sudo.enable = false;
      sudo-rs.enable = true;

      # Always flush L1 cache before entering a guest.
      virtualisation.flushL1DataCache = "always";
    };
  };
}
