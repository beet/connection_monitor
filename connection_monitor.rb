require "socket"
require "ostruct"
require "timeout"

Dir["#{__dir__}/lib/**/*.rb"].each do |file|
  require_relative file
end

class ConnectionMonitor
  POLLING_INTERVAL = 3
  CONNECTION_STATUSES = OpenStruct.new(online: 1, offline: 0)

  using ColourizedStrings
  using TimeFormats

  attr_reader :outages, :connection_status

  def initialize(args)
    @outages = []
    @connection_status = nil
    @debug_mode = args.include?("--debug")
  end

  def start
    while true
      current_connection_status = get_connection_status

      if current_connection_status != connection_status
        if current_connection_status == CONNECTION_STATUSES.online
          close_current_outage
        end

        if current_connection_status == CONNECTION_STATUSES.offline
          open_new_outage
        end

        @connection_status = current_connection_status

        alert
      end

      log_connection_attempt

      print_connection_status

      sleep POLLING_INTERVAL
    end
  rescue Interrupt => exception
    print_outage_summary
  end

  def connection_status_string
    online? ? "Online" : "Off-line"
  end

  def online?
    connection_status == CONNECTION_STATUSES.online
  end

  def offline?
    connection_status == CONNECTION_STATUSES.offline
  end

  def debug_mode?
    @debug_mode == true
  end

  private

  def get_connection_status
    if debug_mode?
      return rand(100) > 75 ? CONNECTION_STATUSES.online : CONNECTION_STATUSES.offline
    end

    begin
      Timeout::timeout(5, Errno::EHOSTUNREACH) do
        if socket = TCPSocket.new("google.com", 80)
          socket.close

          return CONNECTION_STATUSES.online
        end
      end
    rescue SocketError, Errno::EHOSTUNREACH => e
      return CONNECTION_STATUSES.offline
    end
  end

  def uri
    URI("https://www.google.com")
  end

  def print_connection_status
    print "\e[2J\e[f"

    puts "Connection status: #{connection_status_string}".send(online? ? :green : :red)
    puts "Outages:           #{outages_count}, #{outage_duration_string}"

    return if current_outage.nil?

    puts "Current outage:    #{current_outage.summary}".yellow if offline?
    puts "Last outage:       #{current_outage.summary}" if online?
  end

  def alert
    Process.spawn(%(osascript -e 'display notification "#{outages_count} outages" with title "Internet Connection Monitor" subtitle "#{connection_status_string}" sound name "Submarine"'))

    Process.spawn(%(osascript -e 'say "Internet connection #{connection_status_string}"'))
  end

  def open_new_outage
    @outages << ConnectionOutage.new
  end

  def outages_count
    outages.size
  end

  def log_connection_attempt
    return if online?

    current_outage.log_attempt
  end

  def close_current_outage
    current_outage.close if current_outage
  end

  def current_outage
    outages.last
  end

  def print_outage_summary
    puts "\n\nInternet connection experienced #{outages_count} outages for a total of #{outage_duration_string}:\n\n"

    puts outages.map(&:summary).join("\n")
  end

  def outage_duration_string
    # Time.at(total_duration_seconds).gmtime.strftime('%R:%S')
    total_duration_seconds.to_duration_string
  end

  def total_duration_seconds
    outages.sum(&:duration_seconds)
  end
end

ConnectionMonitor.new(ARGV).start
