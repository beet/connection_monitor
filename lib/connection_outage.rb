require_relative "#{__dir__}/time_formats.rb"

class ConnectionOutage
  using TimeFormats

  attr_reader :start_time, :attempts

  def initialize
    @start_time = Time.now
    @attempts = 0
  end

  def log_attempt
    @attempts += 1
  end

  def duration_string
    # Time.at(duration_seconds).gmtime.strftime('%R:%S')
    duration_seconds.to_duration_string
  end

  def duration_seconds
    end_time - start_time
  end

  def end_time
    @end_time || Time.now
  end

  def close
    @end_time = Time.now
  end

  def summary
    "%s - %s, duration %s, %d attempts" % [
      start_time.to_time_string,
      end_time.to_time_string,
      duration_string,
      attempts
    ]
  end
end
