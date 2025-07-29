# Public Load Balancer for the application
resource "google_compute_global_forwarding_rule" "this" {
  count      = var.enable_load_balancer ? 1 : 0
  name       = var.load_balancer_name
  target     = google_compute_target_http_proxy.this[0].id
  port_range = tostring(var.load_balancer_port)
  ip_address = google_compute_global_address.this[0].address
}

resource "google_compute_global_address" "this" {
  count = var.enable_load_balancer ? 1 : 0
  name  = "app-global-ip"
}

resource "google_compute_target_http_proxy" "this" {
  count   = var.enable_load_balancer ? 1 : 0
  name    = "app-http-proxy"
  url_map = google_compute_url_map.this[0].id
}

resource "google_compute_url_map" "this" {
  count           = var.enable_load_balancer ? 1 : 0
  name            = "app-url-map"
  default_service = google_compute_backend_service.this[0].id
}

resource "google_compute_backend_service" "this" {
  count       = var.enable_load_balancer ? 1 : 0
  name        = var.backend_service_name
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = var.backend_service_timeout

  backend {
    group                 = google_compute_network_endpoint_group.this[0].id
    balancing_mode        = var.balancing_mode
    max_rate_per_endpoint = var.max_rate_per_endpoint
  }

  health_checks = [google_compute_health_check.this[0].id]
}

resource "google_compute_network_endpoint_group" "this" {
  count        = var.enable_load_balancer ? 1 : 0
  name         = var.neg_name
  network      = google_compute_network.this.id
  subnetwork   = google_compute_subnetwork.this.id
  default_port = var.app_nodeport
  zone         = var.gcp_zone
}

resource "google_compute_network_endpoint" "this" {
  count                  = var.enable_load_balancer ? 1 : 0
  network_endpoint_group = google_compute_network_endpoint_group.this[0].name
  zone                   = var.gcp_zone
  instance               = google_compute_instance.this.name
  ip_address             = google_compute_instance.this.network_interface[0].network_ip
  port                   = var.app_nodeport
}

resource "google_compute_health_check" "this" {
  count = var.enable_load_balancer ? 1 : 0
  name  = var.health_check_name

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
} 