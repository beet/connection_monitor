require 'net/http'

class ConnectionMonitor
  attr_reader :attempts

  def initialize
    @attempts = 0
  end

  def start
    while internet_down? do
      print "."

      sleep 10
    end

    puts "\n\nInternet back online after #{@attempts} attempts!"

    `say "Internet is back online"`
  end

  private

  def internet_down?
    begin
      return false if Net::HTTP.get(uri)
    rescue SocketError => e
      @attempts += 1

      return true
    end
  end

  def uri
    URI("https://google.com")
  end
end

ConnectionMonitor.new.start
