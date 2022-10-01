# Basic cluster monitoring

Try to move deployment to the nomad.

## Before start

### Prometheus and Consul

Prometheus in this example uses base auth and that means, that plain text password have to be defined in prometheus.yml. To prevent password leak this deploy uses consul key/val storage and keep the password in path **monitoring/node_exporter**. So before deployment you should set this value.


### Node exporter

At the node exporter the configuration should looks like (more anout it is [in the official documentation](https://prometheus.io/docs/guides/basic-auth/)):


```yaml
# /etc/node_exporter/web_config.yml
basic_auth_users:
  agent: $2a$12$c8KpEEEEEXxxxxAAAAAmPPPPPlllllEEEEEEEEEEEEEE0bYXG6O

```



```bash
/usr/local/bin/node_exporter \
    --collector.textfile \
    --collector.textfile.directory=/tmp/metrics \
    --web.config=/etc/node_exporter/config.yaml \
    --web.listen-address=0.0.0.0:9100 \
    --web.telemetry-path=/metrics   
```

## Prometheus enpoint deffinition



## Prometheus alertmanager deffinition



## Prometheus templates