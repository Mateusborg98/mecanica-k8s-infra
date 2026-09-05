locals {
  common_tags = ["project:mecanica", "env:${var.environment}", "managed-by:terraform"]
}

resource "datadog_dashboard_json" "mecanica" {
  dashboard = templatefile("${path.module}/dashboard.json.tftpl", { environment = var.environment })
}

resource "datadog_monitor" "api_unavailable" {
  name    = "[Mecânica][${upper(var.environment)}] API indisponível"
  type    = "service check"
  message = "A API da oficina não respondeu ao healthcheck. Verifique os pods e os logs correlacionados no dashboard."
  query   = "\"http.can_connect\".over(\"env:${var.environment}\",\"service:mecanica-api\").by(\"host\").last(3).count_by_status()"
  monitor_thresholds {
    critical = 2
    warning  = 1
    ok       = 1
  }
  notify_no_data    = true
  no_data_timeframe = 10
  tags              = local.common_tags
}

resource "datadog_monitor" "processing_failures" {
  name    = "[Mecânica][${upper(var.environment)}] Falha no processamento de ordem de serviço"
  type    = "query alert"
  message = "Foi detectada falha no processamento de ordem de serviço. Consulte os logs usando o correlationId."
  query   = "sum(last_5m):sum:mecanica.ordens_servico.processamento.falhas{env:${var.environment}}.as_count() > 0"
  monitor_thresholds {
    critical = 0
  }
  include_tags = true
  tags         = local.common_tags
}

resource "datadog_monitor" "api_latency" {
  name    = "[Mecânica][${upper(var.environment)}] Latência elevada da API"
  type    = "query alert"
  message = "A latência média da API ultrapassou dois segundos nos últimos cinco minutos."
  query   = "sum(last_5m):sum:mecanica.api.http.requests.duration.sum{env:${var.environment}}.as_count() / sum:mecanica.api.http.requests.duration.count{env:${var.environment}}.as_count() > 2"
  monitor_thresholds {
    critical = 2
    warning  = 1
  }
  require_full_window = false
  include_tags        = true
  tags                = local.common_tags
}

resource "datadog_monitor" "kubernetes_cpu" {
  name    = "[Mecânica][${upper(var.environment)}] CPU elevada no Kubernetes"
  type    = "query alert"
  message = "O consumo de CPU dos containers da aplicação permaneceu elevado."
  query   = "avg(last_10m):avg:kubernetes.cpu.usage.total{env:${var.environment},kube_namespace:mecanica} by {pod_name} > 800000000"
  monitor_thresholds {
    critical = 800000000
    warning  = 600000000
  }
  require_full_window = false
  include_tags        = true
  tags                = local.common_tags
}
