---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - localhost:9093

rule_files:
- /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: 'cadvisor'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['cadvisor-cadvisor']

    metrics_path: /metrics

  - job_name: 'node'
    basic_auth:
      username: agent
      password: $2a$12$c8KpSq9ZzKmccaxAvE5uH.K1.Al1C5oFyHWWJwNCZWVH3n0bYXG6O
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
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
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']