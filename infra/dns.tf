resource "aws_route53_record" "headercheck_dns_record" {
  zone_id = data.aws_route53_zone.headercheck_zone.zone_id
  name    = "tm.abdirahimabdi.co.uk"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

import {
  to = aws_route53_record.headercheck_dns_record
  id = "Z01552253DTZ5LRLALWP1_tm.abdirahimabdi.co.uk_A"
}