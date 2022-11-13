---
global:
  scrape_interval:     30s
  evaluation_interval: 10s
  external_labels:
    origin_prometheus: fejk-prometheus
    env: prod
    location: 

{{ if nomadVarExists "nomad/jobs/prometheus" }}
{{ with nomadVar "nomad/jobs/prometheus" }}
remote_write:
- url: '{{ .url }}'
  basic_auth:
    username: '{{ .username }}'
    password: '{{ .password }}'
{{ end }}
{{ end }}

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - localhost:9093

rule_files:
- /etc/prometheus/rules/*.yml

scrape_configs:
  # - job_name: 'cadvisor'

  #   consul_sd_configs:
  #   - server: 'consul.service.consul:8500'
  #     services: ['cadvisor-cadvisor']

  #   metrics_path: /metrics


  - job_name: 'node'
#   scheme: https
    basic_auth:
{{ if nomadVarExists "nomad/jobs/prometheus" }}
{{ with nomadVar "nomad/jobs/prometheus" }}
      username: '{{ .node_exporter_username }}'
      password: '{{ .node_exporter_password }}'
{{ end }}
{{ end }}
    consul_sd_configs:
    - server: '172.17.0.1:8500'
      services: ['nomad-client']
      
    metrics_path: /metrics
    relabel_configs:
    # get ip from label and add my custom port
    - source_labels: ['__address__']
      regex: ([^:]+)(?::\d+)?
      action: replace
      replacement: $1:9100
      target_label: __address__

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '172.17.0.1:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 30s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']

  - job_name: 'application_metrics'

    consul_sd_configs:
    - server: '172.17.0.1:8500'
      services: ['public','monitoring']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 30s
    metrics_path: /metrics
