variable "dcs" {
    type = list(string)
    default = ["dc1", "dev"]
}

variable "fqdn" {
    type = string
    default = "prometheus.fejk.net"
}

job "prometheus" {
  datacenters = var.dcs
  type        = "service"
  namespace   = "system"

  constraint {
    attribute = attr.unique.hostname
    value     = "n1.fejk.net"
  }

  group "prometheus" {
    count = 1

    // Disallow moving this group to another node
    // Sticky deployment
    reschedule {
      attempts  = 0
      unlimited = false
    }


    network {
      mode = "bridge"

      dns {
        servers = ["172.17.0.1", "8.8.8.8", "1.1.1.1"]
      }

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

/*
    service {
      name = "alertmanager"
      port = "alertmanager_ui"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.alertmanager-http.rule=Host(`alerts.fejk.net`)",
      ]
    }
*/
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 500
      sticky = true
      migrate = true
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"
        
        args = [
          "--log.level=debug",
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
        ]

        volumes = [
          "local/config:/etc/prometheus",
        ]

        ports = ["prometheus_ui"]

      }
      
      resources {
        cpu = 600
        memory = 128
        memory_max = 256
      }

      template {
        change_mode = "restart"
        destination = "local/config/prometheus.yml"
        data = file("./config/prometheus.yml.tpl")
      }

      // template {
      //   change_mode = "restart"
      //   destination = "local/config/alertmanager.yml"
      //   data = file("./config/alertmanager.yml.tpl")
      // }


    } # END prometheus


/*
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
*/



  }
}
