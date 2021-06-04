require "socket"
require "ostruct"
require "timeout"

=begin
Object to encapsulate connection status:

    current_connection_status = ConnectionStatus.new

    # Attempts to open a TCP socket to Google
    current_connection_status.online?
    => true

    new_connection_status = ConnectionStatus.new
    new_connection_status.online?
    => false

Connection status objects are comparable:

    new_connection_status == current_connection_status
    => false

Sub-classes provide instances with an explicit status:

    online = ConnectionStatus::Online.new
    online.online?
    => true

    offline = ConnectionStatus::Offline.new
    offline.online?
    => false

    online == offline
    => false

A null-object is provided to allow status comparisons with an undefined
connection state:

    connection_status = ConnectionStatus::Null.new
    connection_status.online?
    => false

    connection_status == ConnectionStatus::Online.new
    => false

=end
class ConnectionStatus
  include Comparable

  CONNECTION_STATUSES = OpenStruct.new(online: 1, offline: 0)
  TIMEOUT_INTERVAL = 5
  URL = "google.com"

  class << self
    def online
      CONNECTION_STATUSES.online
    end

    def offline
      CONNECTION_STATUSES.offline
    end
  end

  attr_reader :exception

  def initialize
    @exception = nil
  end

  def online?
    status == CONNECTION_STATUSES.online
  end

  def offline?
    status == CONNECTION_STATUSES.offline
  end

  def <=>(other)
    status <=> other.status
  end

  # Attempts to open a TCP connection with a timeout limit, catching connection
  # errors and returning a status accordingly:
  #
  # * `SocketError`: failed to open a socket
  # * `Errno::ENETUNREACH`: socket error, for example switching from wifi to a 4G
  #   hotspot that is not providing data
  # * `Errno::EHOSTUNREACH`: socket connection timed out
  def status
    @status ||= begin
      Timeout::timeout(TIMEOUT_INTERVAL, Errno::EHOSTUNREACH) do
        if socket = TCPSocket.new(URL, 80)
          socket.close

          CONNECTION_STATUSES.online
        end
      end
    rescue SocketError, Errno::EHOSTUNREACH, Errno::ENETUNREACH => exception
      @exception = exception

      CONNECTION_STATUSES.offline
    end
  end

  # Dummy connection status that is in an online state
  class Online < ConnectionStatus
    # True
    def online?
      true
    end

    # False
    def offline?
      false
    end

    # Online
    def status
      CONNECTION_STATUSES.online
    end
  end

  # Dummy connection status that is in an offline state
  class Offline < ConnectionStatus
    # False
    def online?
      false
    end

    # True
    def offline?
      true
    end

    # Offline
    def status
      CONNECTION_STATUSES.offline
    end
  end

  # Dummy connection status that is in undefined state
  class Null < ConnectionStatus
    # False
    def online?
      false
    end

    # False
    def offline?
      false
    end

    # Nil
    def status
      nil
    end
  end
end
