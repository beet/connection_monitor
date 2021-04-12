# require "date"
require_relative "#{__dir__}/time_formats.rb"

class OutageReport
  using TimeFormats

  attr_reader :outages

  def initialize(outages)
    @outages = outages
  end

  def run
    "".tap do |report|
      dates.each do |date|
        report << "\n"

        outages_for_date(date).tap do |outages_for_date|
          total_duration = outages_for_date.sum(&:duration_seconds)

          report << "#{date.to_date_string}: out for #{total_duration.to_duration_string}\n\n"

          outages_for_date.each do |outage|
            report << "* #{outage.short_summary}\n"
          end
        end
      end
    end
  end

  private

  def dates
    outages.map(&:date).uniq
  end

  def outages_for_date(date)
    outages.select do |outage|
      outage.date == date
    end
  end
end
