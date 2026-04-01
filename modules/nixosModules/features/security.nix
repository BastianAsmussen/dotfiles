{
  flake.nixosModules.security = {pkgs, ...}: {
    boot = {
      kernel.sysctl = {
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

        # Defeats KASLR info-leaks via /proc/kallsyms.
        "kernel.kptr_restrict" = 2;
        # Prevents LPE exploits from harvesting driver addresses in dmesg.
        "kernel.dmesg_restrict" = 1;
        # User namespaces reach rarely-tested kernel surfaces (CVE-2022-0185 etc.).
        "kernel.unprivileged_userns_clone" = 0;
        # Stops same-user processes from ptracing ssh-agent/gpg-agent.
        "kernel.yama.ptrace_scope" = 1;
      };

      kernelModules = ["tcp_bbr"];

      kernelParams = [
        "slab_nomerge"
        "init_on_alloc=1"
        "init_on_free=1"
        "page_alloc.shuffle=1"
        "randomize_kstack_offset=on"
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
      polkit.enable = true;
      rtkit.enable = true;

      sudo.enable = false;
      sudo-rs.enable = true;

      virtualisation.flushL1DataCache = "always";
    };

    networking.firewall.logReversePathDrops = true;
  };
}
