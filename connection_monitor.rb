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

  attr_reader :attempts, :outages, :connection_status

  def initialize
    @attempts = 0
    @outages = 0
    @connection_status = nil
  end

  def start
    while true
      current_connection_status = get_connection_status

      if current_connection_status != connection_status
        if current_connection_status == CONNECTION_STATUSES.online
          @attempts = 0
        end

        if current_connection_status == CONNECTION_STATUSES.offline
          @outages += 1
        end

        @connection_status = current_connection_status

        alert
      end

      print_connection_status

      sleep POLLING_INTERVAL
    end
  rescue Interrupt => exception
    puts "\n\nInternet connection experienced #{outages} outages"
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

  private

  def get_connection_status
    begin
      Timeout::timeout(5, Errno::EHOSTUNREACH) do
        if socket = TCPSocket.new("google.com", 80)
          socket.close

          return CONNECTION_STATUSES.online
        end
      end
    rescue SocketError, Errno::EHOSTUNREACH => e
      @attempts += 1

      return CONNECTION_STATUSES.offline
    end
  end

  def uri
    URI("https://www.google.com")
  end

  def print_connection_status
    print "\e[2J\e[f"

    puts "Connection status: #{connection_status_string}".send(online? ? :green : :red)
    puts "Outages:           #{outages}"
    puts "Attempts:          #{attempts}".yellow if offline?
  end

  def alert
    Process.spawn(%(osascript -e 'display notification "#{@outages} outages" with title "Internet Connection Monitor" subtitle "#{connection_status_string}" sound name "Submarine"'))

    Process.spawn(%(osascript -e 'say "Internet connection #{connection_status_string}"'))
  end
end

ConnectionMonitor.new.start
