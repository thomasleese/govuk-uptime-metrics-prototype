#!/usr/bin/env ruby

# Usage: ./collect.rb <path> <service>

require "csv"
require "fileutils"
require "net/http"
require "time"

def check_status(service)
  uri = URI("https://#{service}.publishing.service.gov.uk/healthcheck")
  response = Net::HTTP.get(uri)
  response == "OK"
end

def append_to_csv(filename, service, status)
  CSV.open(filename, "ab") do |csv|
    csv << [service, Time.now.utc.iso8601, status]
  end
end

def main
  path = ARGV[0]
  service = ARGV[1]

  FileUtils.mkpath("#{path}/tmp")
  csv_filename = "#{path}/tmp/#{Time.now.utc.strftime('%Y-%m-%d')}.csv"

  status = check_status(service)
  append_to_csv(csv_filename, service, status)
end

main