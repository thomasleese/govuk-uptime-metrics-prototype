#!/usr/bin/env ruby

# Usage: ./collect.rb <path> <service>

require "csv"
require "fileutils"
require "net/http"
require "time"
require "statsd"

class Collector
  def initialize(service)
    @statsd = Statsd.new("127.0.0.1")
    @service = service
  end

  def call
    while true
      send_to_statsd(check_status)
      sleep 5
    end
  end

private

  attr_reader :statsd, :service

  def healthcheck_uri
    @healthcheck_uri ||= URI("https://#{service}.publishing.service.gov.uk/healthcheck")
  end

  def check_status
    Net::HTTP.get(healthcheck_uri) == "OK"
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

  ARGV.each do |service|
    threads << Thread.new do
      Collector.new(service).call
    end
  end

  threads.each { |thread| thread.join }
end

main
