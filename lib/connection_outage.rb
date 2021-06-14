require "date"
require_relative "#{__dir__}/time_formats"
require_relative "#{__dir__}/colourized_strings"

=begin
Object to represent an connection outage:

    outage = ConnectionOutage.new

    outage.log_attempt

    outage.attempts
    => 1

    outage.duration_seconds
    => 3

    outage.resolved?
    => false

    outage.long_summary
    => "2021-06-04 14:55:07 - 2021-06-04 14:55:16, duration 00:00:09, 3 attempts"

    outage.short_summary
    => "14:55:07 - 14:55:16, duration 00:00:09, 3 attempts"

    outage.close
    => #<Time...>

=end
class ConnectionOutage
  using TimeFormats
  using ColourizedStrings

  attr_reader :start_time, :attempts, :connection_status

  def initialize(connection_status)
    @start_time = Time.now
    @attempts = 0
    @connection_status = connection_status
  end

  # Increment a counter each time a connection attempt is made
  def log_attempt
    @attempts += 1
  end

  # Outage duration
  def duration_seconds
    end_time - start_time
  end

  # True if the outage has an end time
  def resolved?
    !@end_time.nil?
  end

  # Marks the outage as resolved by timestamping the end time
  def close
    @end_time = Time.now
  end

  # Show a long summary of the outage including the start & end date & time, the
  # connection error, duration, and no. of connection attempts.
  def long_summary
    "%s - %s, %s, duration %s, %d attempts" % [
      start_time.long_time_string,
      end_time.long_time_string,
      connection_status.error_message,
      duration_string.underline,
      attempts
    ]
  end

  # Show a short summary of the outage showing the start & end time, connection
  # error, duration, and no. of attempts
  def short_summary
    "%s - %s, %s, duration %s, %d attempts" % [
      start_time.short_time_string.light_blue,
      end_time.short_time_string.light_blue,
      connection_status.error_message,
      duration_string.underline,
      attempts
    ]
  end

  # The date that the outage began
  def date
    start_time.to_date
  end

  private

  def end_time
    @end_time || Time.now
  end

  def duration_string
    duration_seconds.to_duration_string
  end
end
