require 'net/http'
require "ostruct"

class ConnectionMonitor
  POLLING_INTERVAL = 3
  CONNECTION_STATUSES = OpenStruct.new(online: 1, offline: 0)

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

        `say "Internet connection #{connection_status_string}"`
      end

      print online? ? "." : "X"

      sleep POLLING_INTERVAL
    end
  rescue Interrupt => exception
    puts "\n\nInternet connection experienced #{outages} outages"
  end

  def connection_status_string
    online? ? "online" : "off-line"
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
      return CONNECTION_STATUSES.online if Net::HTTP.get(uri)
    rescue SocketError => e
      @attempts += 1

      return CONNECTION_STATUSES.offline
    end
  end

  def uri
    URI("https://www.google.com")
  end
end

ConnectionMonitor.new.start
