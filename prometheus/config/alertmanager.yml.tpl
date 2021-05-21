global:
  resolve_timeout: 5m
  slack_api_url: https://hooks.slack.com/services/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

route:
  group_by: ['alertname']
  group_wait: 120s
  group_interval: 60s
  repeat_interval: 300s
  #receiver: 'email'
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#alerts'
    send_resolved: true

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