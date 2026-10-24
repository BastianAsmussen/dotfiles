data "cloudflare_zone" "covenant" {
  filter = {
    name = "covenantofearth.org"
  }
}

# DNS-AID index, per draft-mozleywilliams-dnsop-dnsaid-02.
resource "cloudflare_dns_record" "covenant_agents_index" {
  zone_id = data.cloudflare_zone.covenant.zone_id
  name    = "_index._agents.covenantofearth.org"
  type    = "SVCB"
  ttl     = 3600

  data = {
    priority = 1
    target   = "covenantofearth.org."
    value    = "alpn=\"http/1.1\" port=443 well-known=ai-catalog.json"
  }
}

resource "cloudflare_zone_dnssec" "covenant" {
  zone_id = data.cloudflare_zone.covenant.zone_id
  status  = "active"
}

# Enter at Name.com, the registrar, to complete the chain of trust.
output "covenant_ds" {
  value = cloudflare_zone_dnssec.covenant.ds
}
