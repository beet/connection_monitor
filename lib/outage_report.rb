require_relative "#{__dir__}/time_formats.rb"

=begin
Object that tages a collection of connection outages and prints out a report:

    report = OutageReport.new(outages)

    report.run

Produces an output like:

    Connection status: Off-line
    Outages:           6, 00:00:53
    Daemon:            Not running
    Current outage:    2021-06-04 15:14:48 - 2021-06-04 15:15:06, duration 00:00:17, 0 attempts

    Fri 04 Jun, 2021-06-04: out for 00:00:53

    * 15:13:57 - 15:14:00, duration 00:00:03, 1 attempts
    * 15:14:03 - 15:14:12, duration 00:00:09, 3 attempts
    * 15:14:15 - 15:14:24, duration 00:00:09, 3 attempts
    * 15:14:27 - 15:14:33, duration 00:00:06, 2 attempts
    * 15:14:36 - 15:14:45, duration 00:00:09, 3 attempts
    * 15:14:48 - 15:15:06, duration 00:00:17, 0 attempts

=end
class OutageReport
  using TimeFormats

  attr_reader :outages

  def initialize(outages)
    @outages = outages
  end

  # Prodce a report of outage summaries
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
