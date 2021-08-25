variable "dcs" {
    type = list(string)
    default = ["dc1", "dev"]
}

variable "fqdn" {
    type = string
}

job "monitoring" {
  datacenters = var.dcs
  type        = "service"
  namespace   = "system"

  group "prometheus" {
    count = 1

    // Disallow moving this group to another node
    // Sticky deployment
    reschedule {
      attempts  = 0
      unlimited = false
    }


    network {
      port "prometheus_ui" {
        to = "9090"
      }

      port "alertmanager_ui" {
        to = "9093"
      }

    }

    service {
      name = "prometheus"
      port = "prometheus_ui"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prometheus-http.rule=Host(`${var.fqdn}`)",
      ]

      check {
        name     = "prometheus_ui port alive"
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "alertmanager"
      port = "alertmanager_ui"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.alertmanager-http.rule=Host(`alerts.fejk.net`)",
      ]
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 300
      sticky = true
      migrate = true
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
          "local/rules:/etc/prometheus/rules",
        ]

        ports = ["prometheus_ui"]

      }
      
      resources {
        cpu = 600
        memory = 128
        memory_max = 256
      }

      // artifact {
      //   source      = "https://github.com/theztd/flaskapp-prom/archive/refs/tags/v0.1.14p1.tar.gz"
      //   destination = "local/templates"
      // }

      template {
        change_mode = "restart"
        destination = "local/prometheus.yml"
        data = file("./config/prometheus.yml.tpl")
      }

      artifact {
        source      = "https://raw.githubusercontent.com/theztd/monitoring/main/prometheus/config/rules/node_alerts.yml"
        destination = "local/rules/"
      }

    } # END prometheus

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:latest"

        volumes = [
          "local/alertmanager.yml:/etc/prometheus/alertmanager.yml",
        ]

        ports = ["alertmanager_ui"]

      }
      
      resources {
        cpu = 100
        memory = 16
        memory_max = 64
      }


      template {
        change_mode = "restart"
        destination = "local/alertmanager.yml"
        data = file("./config/alertmanager.yml.tpl")
      }

    } # END alertmanager




  }
}
