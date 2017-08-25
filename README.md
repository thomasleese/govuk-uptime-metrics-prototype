# govuk-uptime-metrics-prototype

A prototype on how we could collect uptime metrics on GOV.UK

## Usage

Run the collector which will send the data to statsd.

```fish
while true
  ./collect.rb specialist-publisher travel-advice-publisher
  sleep 1m
end
```
