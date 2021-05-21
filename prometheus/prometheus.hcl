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
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]

        ports = ["prometheus_ui"]

      }
      
      resources {
        cpu = 100
        memory = 48
        memory_max = 128
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

    } # END prometheus

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:latest"

        volumes = [
          "local/alertmanager.yml:/etc/prometheus/alertmanager.yml",
          "local/rules/:/etc/prometheus/rules/",
        ]

        ports = ["alertmanager_ui"]

      }
      
      resources {
        cpu = 20
        memory = 16
        memory_max = 64
      }


      template {
        change_mode = "restart"
        destination = "local/alertmanager.yml"
        data = file("./config/alertmanager.yml.tpl")
      }

      // template {
      //   change_mode = "restart"
      //   destination = "local/rules/node_alerts.yml"
      //   data = file("./config/rules/node_alerts.yml")
      // }


    } # END alertmanager




  }
}