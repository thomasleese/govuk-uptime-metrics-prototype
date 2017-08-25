#!/usr/bin/env ruby

# Usage: ./collect.rb <environment> <service ...>

require "csv"
require "fileutils"
require "net/http"
require "time"
require "statsd"

class Array
  def each_after(n)
    each_with_index do |elem, i|
      yield elem if i >= n
    end
  end
end

class Collector
  def initialize(service, environment)
    @statsd = Statsd.new("127.0.0.1")
    @service = service
    @environment = environment
  end

  def call
    while true
      send_to_statsd(check_status)
      sleep 5
    end
  end

private

  attr_reader :statsd, :service, :environment

  def healthcheck_uri
    @healthcheck_uri ||= (if environment == "production"
      URI("https://#{service}.publishing.service.gov.uk/healthcheck")
    else
      URI("https://#{service}.#{environment}.publishing.service.gov.uk/healthcheck")
    end)
  end

  def check_status
    http = Net::HTTP.new(healthcheck_uri.host, healthcheck_uri.port)
    http.use_ssl = true

    request = Net::HTTP::Head.new(healthcheck_uri.request_uri)
    res = http.request(request)

    status_code = res.code.to_i
    status_code >= 200 && status_code <= 299
  end

  def send_to_statsd(status)
    statsd.gauge("uptime.#{service}", status ? 1 : 0)
  end
end

# def append_to_csv(filename, service, status)
#   CSV.open(filename, "ab") do |csv|
#     csv << [service, Time.now.utc.iso8601, status]
#   end
# end

def main
  threads = []

  environment = ARGV[0]

  ARGV.each_after(1) do |service|
    threads << Thread.new do
      Collector.new(service, environment).call
    end
  end

  threads.each { |thread| thread.join }
end

main
