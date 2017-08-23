# govuk-uptime-metrics-prototype

A prototype on how we could collect uptime metrics on GOV.UK

## Usage

First you have to collect uptime data on a service:

```fish
while true
  ./collect.rb data specialist-publisher
  sleep 1m
end
```

Once you have one day's worth of data you can aggregate it into something more useful:

```fish
./aggregate.rb data
```
