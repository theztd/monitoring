global:
  resolve_timeout: 5m
  slack_api_url: https://hooks.slack.com/services/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

route:
  group_by: ['alertname']
  group_wait: 5m
  group_interval: 5m
  repeat_interval: 60m
  #receiver: 'email'
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#server-events-stage'
    send_resolved: true
    title: |-
      [{{ .Status }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}
    text: >-
      {{ with index .Alerts 0 -}}
        :chart_with_upwards_trend: *<{{ .GeneratorURL }}|Graph>*
        {{- if .Annotations.runbook }}   :notebook: *<{{ .Annotations.runbook }}|Runbook>*{{ end }}
      {{ end }}

      *Alert details*:

      {{ range .Alerts -}}
        *Alert:* {{ .Annotations.title }}{{ if .Labels.severity }} - `{{ .Labels.severity }}`{{ end }}
      *Description:* {{ .Annotations.description }}
      *Details:*
        {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
        {{ end }}
      {{ end }}

- name: 'email'
  email_configs:
  - to: 'msirovy@gmail.com'
    from: 'alerts@fejk.net'
    smarthost: localhost:25
    require_tls: false
#    smarthost: smtp.gmail.com:587
#    auth_username: 'mail_id@gmail.com'
#    auth_identity: 'mail_id@gmail.com'
#    auth_password: 'password'


inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
