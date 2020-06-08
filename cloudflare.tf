data cloudflare_zones zone {
  filter {
    name   = var.domain
  }
}

resource cloudflare_record instance {
  count    = var.provision_cloudflare_dns ? var.instance_count : 0
  zone_id  = element(data.cloudflare_zones.zone.zones, 0).id
  name     = var.hostname
  value    = aws_instance.instance[count.index].public_ip
  type     = "A"
  proxied  = false
}
