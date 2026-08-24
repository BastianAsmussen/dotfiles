---
name: nixos-nginx-proxy
description: Use when configuring the custom nginx module in this flake. Reverse proxies, mTLS, stream (TLS passthrough), redirects, ACME DNS-01, and proxySSL.
---

# Configuring the Nginx Reverse Proxy Module

The custom nginx module (`modules/nixosModules/features/nginx.nix`) provides a unified configuration interface for reverse proxies, redirects, and stream (TLS passthrough) proxying.

## Module Structure

```nix
nginx = {
  enable = true;
  openFirewall = true;
  acme.email = "admin@example.com";
  acme.sharedHost = null;              # wildcard ACME host name
  streamProxy = { ... };               # TLS SNI passthrough
  reverseProxies = { ... };            # HTTP reverse proxies
  redirects = { ... };                # HTTP -> HTTPS redirects
};
```

## Reverse Proxies

Declare under `nginx.reverseProxies`:

```nix
nginx.reverseProxies = {
  myService = {
    domain = "my-app.asmussen.tech";
    location = "/";
    upstream = "http://localhost:8080";
    proxyWebsockets = true;
    forceSSL = true;

    ssl = {
      useACME = true;
      dnsProvider = "cloudflare";         # DNS-01 challenge
      environmentFile = config.sops.templates."cloudflare-acme-env".path;
    };
  };
};
```

Multiple services on the same domain share a single virtual host at different `location` paths. All proxies sharing a domain must agree on SSL settings (enforced by assertions).

### mTLS (Mutual TLS)

Lock down a proxy by requiring client certificates:

```nix
nginx.reverseProxies = {
  privateService = {
    domain = "private.asmussen.tech";
    location = "/";
    upstream = "http://localhost:9000";

    mtls = {
      enable = true;
      caCertificate = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
      localhostBypass = true;   # allow 127.0.0.1/::1 without client cert
    };
  };
};
```

### ProxySSL (Client Certificate for Upstream)

When the proxy itself needs to present a client certificate to the upstream:

```nix
nginx.reverseProxies = {
  remoteService = {
    domain = "remote.asmussen.tech";
    location = "/";
    upstream = "https://10.10.0.1";   # through WireGuard

    proxySSL = {
      clientCertificate = config.sops.secrets."mtls/epsilon-client-cert".path;
      clientCertificateKey = config.sops.secrets."mtls/epsilon-client-key".path;
      serverName = "remote.asmussen.tech";   # override SNI
      verify = false;
    };
  };
};
```

Use this when the browser resolves to localhost but traffic tunnels through a WireGuard-based stream proxy (as delta does for epsilon's services).

## Stream Proxy (TLS Passthrough)

The stream proxy mode (`nginx.streamProxy.enable = true`) operates at the TCP level, passing TLS connections through based on SNI without decrypting:

```nix
nginx.streamProxy = {
  enable = true;

  # Static SNI routes.
  sniRoutes = {
    "jellyfin.asmussen.tech" = "10.10.0.2:443";
    "requests.asmussen.tech" = "10.10.0.2:443";
  };

  # Fallback for unmatched SNI (or use stateFile for dynamic routing).
  defaultUpstream = "127.0.0.1:8443";

  # A mutable file that overrides/defaults the map, written by an external
  # health-check daemon (primaryMirror) that detects whether epsilon is reachable.
  stateFile = "/var/lib/primary-mirror/stream-upstream.conf";

  connectTimeout = "3s";
};
```

When stream mode is active, regular HTTP virtual hosts are not created. Only a `:80 -> :443` redirect. The stream module handles TLS termination.

### Pattern: Eta's Stream Proxy

Eta uses stream proxy mode to route internet traffic to epsilon through WireGuard:

- Static `sniRoutes` map known hostnames to epsilon's WireGuard IP
- A `stateFile` is written by `primaryMirror` health checks to toggle between epsilon (primary) and local fallback (127.0.0.1:8443)
- The fallback serves 503 (for proxied services) or the local website (for the root site)

## Redirects

For domain-to-domain redirects (e.g., www -> bare):

```nix
nginx.redirects = {
  www-to-bare = {
    enable = true;
    domain = "www.asmussen.tech";
    target = "https://asmussen.tech";
  };
};
```

## ACME / SSL Notes

- **HTTP-01** (default `ssl.useACME = true` without `dnsProvider`): nginx must be reachable on ports 80/443 from the internet
- **DNS-01** (`ssl.dnsProvider = "cloudflare"` with `environmentFile`): works behind NAT, requires a Cloudflare API token
- **Shared host** (`acme.sharedHost = "asmussen.tech"`): all reverse proxies share one wildcard certificate via `useACMEHost`
- DNS-01 certificates are readable by nginx (group is set to the nginx service group)

## Firewall

Set `nginx.openFirewall = false` when the host is behind a stream proxy or another nginx instance already owns the port (e.g., delta proxies everything through eta's stream). When true, ports 80 and 443 are opened.

## Testing

The module has assertions that catch misconfiguration at eval time:
- `forceSSL` requires either `ssl.useACME` or both `ssl.certificate` + `ssl.certificateKey`
- `dnsProvider` requires `environmentFile`
- `mtls.enable` requires `caCertificate`
- `proxySSL` client cert and key must both be set or both null
- All proxies on the same domain must agree on SSL/mTLS settings
