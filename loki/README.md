# Loki nomad deploj


Comes from docker-compose template

```yaml
    image: grafana/loki:2.4.1
    command: "-config.file=/etc/loki/config.yaml -target=write"
    ports:
      - 3100
      - 7946
      - 9095
    volumes:
      - ./loki-config.yaml:/etc/loki/config.yaml

```



## Usage

Could be tested by curl

```bash
#!/bin/bash

USER=123456
PASSWORD=examplePassword

curl -v -XPOST  -H "Content-Type: application/json" \
    -s "https://$USER:$PASSWORD@logs-prod-us-central1.grafana.net/api/prom/push" \
    -d '{
    "streams": [
        {
            "labels": "{job=\"avocado\",env=\"prod\"}",
            "entries": [
                {
                    "ts": "2022-02-19T07:25:51.801064-00:00",
                    "line": "CURL pokus z formatovaneho curlu"
                }
            ]
        }
    ]
}'

```


And there is a small example in go without libs

```golang
package main

import (
	"bytes"
	"io/ioutil"
	"log"
	"net/http"
)

type config struct {
	Url string
}

func main() {
	var CFG = config{
		Url: "https://user:password@logs-prod-us-central1.grafana.net/api/prom/push",
	}

	var dataJson = []byte(`{
		"streams": [
        {
            "labels": "{job=\"avocado\",env=\"prod\"}",
            "entries": [
                {
                    "ts": "2022-02-19T13:25:51.801064-00:00",
                    "line": "GO - pokus 2 z formatovaneho curlu"
                }
            ]
        }
    ]
	}`)

	req, err := http.NewRequest("POST", CFG.Url, bytes.NewBuffer(dataJson))

	if err != nil {
		log.Panic(err)
	}

	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Panic(err)
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	log.Println(body)

}


```