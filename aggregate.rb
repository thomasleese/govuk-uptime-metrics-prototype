#!/usr/bin/env ruby

# Usage: ./aggregate.rb <path>

require "csv"
require "fileutils"
require "net/http"
require "time"

def group_data(data)
  data.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, hash|
    hash[row[0]] << [Time.parse(row[1]), row[2] == "true"]
  end
end

def aggregate_data(current_date, rows)
  seconds_up = 0

  start_date = Time.parse("#{current_date}T00:00:00Z")
  end_date = Time.parse("#{current_date}T23:59:59Z")

  last_date = start_date
  last_up = nil

  sorted_rows = rows.sort_by { |(date, up)| date }

  sorted_rows.each do |(date, up)|
    seconds_diff = date - last_date
    seconds_up += seconds_diff if up
    last_date = date
    last_up = up
  end

  seconds_up += (end_date - last_date) if last_up

  seconds_up
end

def append_to_csv(filename, service, date, uptime_proportion, downtime_minutes)
  CSV.open(filename, "ab") do |csv|
    csv << [service, date, uptime_proportion, downtime_minutes]
  end
end

def main
  path = ARGV[0]

  csv_filename = "#{path}/uptime.csv"

  seconds_in_day = 24 * 60 * 60 - 1
  current_date = Time.now.utc.strftime("%Y-%m-%d")

  Dir.glob("#{path}/tmp/*.csv") do |filename|
    date = File.basename(filename, ".csv")

    if date == current_date
      puts "Skipping #{date} as that's today!"
      next  # data still being added
    end

    data = CSV.read(filename)
    group_data(data).each do |service, rows|
      seconds_up = aggregate_data(current_date, rows)
      proportion_up = seconds_up / seconds_in_day
      minutes_down = (seconds_in_day - seconds_up) / 60
      append_to_csv(csv_filename, service, date, proportion_up, minutes_down)
    end

    # FileUtils.rm(filename)
  end
end

main
