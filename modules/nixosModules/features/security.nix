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

        # Hide kernel symbol addresses in /proc/kallsyms and other interfaces.
        # Without this, a local attacker (or an info-leak bug) can trivially
        # defeat KASLR by reading raw pointers, making ROP chains easier to
        # construct. Value 2 hides them from everyone, including root processes
        # that lack CAP_SYSLOG.
        "kernel.kptr_restrict" = 2;

        # Restrict dmesg to root (CAP_SYSLOG). The kernel ring buffer often
        # leaks KASLR base offsets, driver addresses, and hardware details that
        # aid local privilege-escalation exploits. Users who need dmesg can use
        # `journalctl -k` with appropriate group membership instead.
        "kernel.dmesg_restrict" = 1;

        # Limit unprivileged user namespaces. User namespaces let unprivileged
        # code reach kernel syscall surfaces (e.g. mount, network) that are
        # rarely tested against hostile callers — they have been the entry point
        # for numerous container-escape and LPE CVEs (e.g. CVE-2022-0185).
        "kernel.unprivileged_userns_clone" = 0;

        # Restrict ptrace to a process's direct descendants only. Without this,
        # any process running as the same user can attach to any other, making
        # it trivial for malware or a compromised browser renderer to read
        # secrets from ssh-agent, GPG agent, or password managers.
        "kernel.yama.ptrace_scope" = 1;
      };

      kernelModules = ["tcp_bbr"];

      kernelParams = [
        # Prevent adjacent slab caches from being merged. Merging saves memory
        # but lets a use-after-free in one cache corrupt objects of a different
        # type, which is the foundation of most modern kernel heap exploits
        # (cross-cache attacks). The memory overhead is minimal on a desktop.
        "slab_nomerge"

        # Zero-fill pages on allocation and free. This stops stale kernel heap
        # data (crypto keys, network buffers, credentials) from leaking to
        # userspace or to subsequently allocated objects. Measured overhead is
        # ~1% on typical desktop workloads.
        "init_on_alloc=1"
        "init_on_free=1"

        # Randomise the order in which the page allocator hands out pages. This
        # makes page-level heap-spraying attacks significantly harder by
        # breaking the predictable allocation patterns they rely on.
        "page_alloc.shuffle=1"

        # Randomise the kernel stack offset on every syscall entry, defeating
        # stack-layout-dependent exploits that rely on deterministic offsets
        # between stack frames. Negligible performance cost.
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
      forcePageTableIsolation = true;
      polkit.enable = true;
      rtkit.enable = true;

      sudo.enable = false;
      sudo-rs.enable = true;

      # Always flush L1 cache before entering a guest.
      virtualisation.flushL1DataCache = "always";
    };

    # Log packets that fail reverse-path filtering. This surfaces spoofed
    # traffic (e.g. from a compromised LAN device) in the system journal so
    # it can be investigated, complementing the rp_filter sysctl above.
    networking.firewall.logReversePathDrops = true;
  };
}
