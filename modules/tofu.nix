{
  perSystem =
    { pkgs, ... }:
    {
      devShells.infra = pkgs.mkShell {
        packages = [
          # null and external are required by the nixos-anywhere module.
          (pkgs.opentofu.withPlugins (p: [
            p.hetznercloud_hcloud
            p.hashicorp_null
            p.hashicorp_external
            p.cloudflare_cloudflare
          ]))
          pkgs.nixos-anywhere
          pkgs.sops
          pkgs.jq
          pkgs.gopass
        ];
      };
    };
}
