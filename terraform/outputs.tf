output "website_endpoint" {
  value = "https://${cloudflare_record.site_cname.hostname}"
}