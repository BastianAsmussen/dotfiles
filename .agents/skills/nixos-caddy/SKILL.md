---
name: nixos-caddy
description: Use when configuring the Caddy reverse proxy in this flake. Virtual hosts, derived ACME certificates, mTLS listeners, PROXY protocol, caddy-l4 SNI passthrough with failover, and rate limiting.
---

# Configuring the Caddy Reverse Proxy

The caddy module (`modules/nixosModules/features/caddy.nix`) wraps `services.caddy`,
derives `security.acme` certificates from virtual hosts, and exposes
listener-level options. Hosts import it as `self.nixosModules.caddy`.

## Module Structure

```nix
caddy = {
  enable = true;                        # default
  extended = true;                     # caddy-l4 + caddy-ratelimit build (epsilon, eta)
  listenAddresses = [ "10.10.0.2" ];    # default vhost bind; empty binds all interfaces
  defaultPort = 443;                   # port appended to vhost names with none (eta: 8443)
  openFirewall = false;                # TCP 80 and 443 on every interface
  servers."10.10.0.2:443" = ''…'';     # per-listener options; key = bind address + port
};
```

## Virtual Hosts

Declare under `services.caddy.virtualHosts` (nixpkgs submodule, extended by this
module):

```nix
services.caddy.virtualHosts."my-app.asmussen.tech".extraConfig = ''
  reverse_proxy localhost:8080
'';
```

Defaults the module adds per vhost:

- `hostName` — the attr name, with `:defaultPort` appended when the name carries
  no port or scheme
- `listenAddresses` — `caddy.listenAddresses`
- `acmeCert` — the registrable domain (last two labels) of the name; `null` for
  `http://` names and bare ports
- `useACMEHost` — `acmeCert`, unless `clientCA` is set (a bare `tls cert key`
  line cannot carry `client_auth`)
- `clientCA` — when set, the site requires a client certificate chaining to
  that CA

## Derived Certificates

For every unique `acmeCert` the module declares `security.acme.certs.<apex>`
with `extraDomainNames = [ "*.<apex>" ]`, the caddy group, and a caddy reload.
One `{ apex, wildcard }` pair per domain keeps service names out of CT logs.

`security.acme.defaults.dnsProvider` must be set (import
`self.nixosModules.acmeShared`); the module asserts this. Global
`auto_https disable_redirects` plus an assertion that every TLS vhost resolves
to a cert mean Caddy never issues on its own; port 80 redirects are declared
explicitly (eta's `http://` catch-all). The snippet `(hsts)` is available to
import in site blocks.

## mTLS

A public site that requires client certificates plus a loopback twin that needs
none:

```nix
services.caddy.virtualHosts = {
  "private.asmussen.tech:8443" = {
    clientCA = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
    extraConfig = "reverse_proxy localhost:9000";
  };

  "private.asmussen.tech" = {
    listenAddresses = [ "127.0.0.1" "::1" ];
    extraConfig = "reverse_proxy localhost:9000";
  };
};
```

The kernel bind decides the bypass, so no forged address can claim it. Epsilon's
five *arr services use this pair.

### Client Certificate Upstream

When the proxy must present a client certificate to its upstream (delta to
epsilon), Caddy verifies the upstream against the system trust store:

```nix
services.caddy.virtualHosts."remote.asmussen.tech".extraConfig = ''
  reverse_proxy https://10.10.0.2:8443 {
    transport http {
      tls_client_auth ${config.sops.secrets."mtls/delta-client-cert".path} ${config.sops.secrets."mtls/delta-client-key".path}
      tls_server_name remote.asmussen.tech
    }
  }
'';
```

## Listeners

`caddy.servers` keys must equal a site's bind address plus port. Epsilon trusts
PROXY headers from eta alone, which is what makes `{remote_host}` the real
client address:

```nix
caddy.servers."10.10.0.2:443" = ''
  listener_wrappers {
    proxy_protocol {
      allow 10.10.0.1/32
    }

    tls
  }
'';
```

`protocols h1 h2` is set globally: HTTP/3 stays off because eta's layer4 routes
are TCP-only, so a UDP Alt-Svc would advertise a path nothing routes.

## SNI Passthrough and Failover

`modules/nixosModules/features/primary-mirror.nix` (eta) renders the `:443`
layer4 routes. `mtlsNames` proxy to epsilon's client-certificate port with no
PROXY header. `passthroughNames` proxy to `[primary:443, local fallback]` with
`proxy_protocol v2`, `lb_policy first`, and an active TCP health check against
`availabilityPort`; the local fallback is healthy because the module keeps its
own always-on probe socket (`primary-mirror-fallback.socket`).

`modules/nixosModules/features/primary-busy.nix` (epsilon) owns the other end:
`primary-available.socket` listens on `10.10.0.2:9444`, gamemode hooks stop and
start it, a timer reconciles, and a polkit rule allows exactly start/stop of
that unit for the user. While the socket is down the mirror's health check
fails and traffic moves to eta's fallback within `fail_duration`.

## Redirects

```nix
services.caddy.virtualHosts."www.example.org".extraConfig =
  "redir https://example.org{uri} permanent";
```

`acmeShared.dkRedirects` renders the .dk domains this way; its `domains`
option also feeds eta's `passthroughNames`.

## Rate Limiting

The extended build carries caddy-ratelimit. Epsilon gates auth endpoints:

```nix
rate_limit {
  zone my_auth {
    match {
      path_regexp (?i)^/login$
    }

    key {remote_host}
    events 5
    window 1m
  }
}
```

## Testing

- `checks.x86_64-linux.caddyfile-<host>` runs `caddy adapt` over each host's
  rendered Caddyfile.
- `checks.x86_64-linux.nixos-vm-caddy-edge` boots edge, primary and client VMs
  and asserts passthrough, failover, the mTLS boundary and the PROXY listener.
- Module assertions: every TLS vhost resolves to a derived cert, every alias
  shares its vhost's apex, and a DNS-01 provider is configured.
