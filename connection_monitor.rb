#!/usr/bin/env ruby
require "socket"
require "ostruct"
require "timeout"
require "fileutils"
require "yaml"

Dir["#{__dir__}/lib/**/*.rb"].each do |file|
  require_relative file
end

class ConnectionMonitor
  POLLING_INTERVAL = 3
  CONNECTION_STATUSES = OpenStruct.new(online: 1, offline: 0)

  include PredicateAttributes
  using ColourizedStrings
  using TimeFormats

  attr_reader :outages, :connection_status

  def initialize(args)
    @outages = []
    @connection_status = nil
    @debug_mode = args.include?("--debug")
    @daemonized = args.include?("--daemonize")
    @stop = args.include?("--stop")
    @show_report = args.include?("--report")
    @show_status = args.include?("--status")
  end

  def start
    show_daemon_summary

    daemonize

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

        print_connection_status if online?

        alert

        write_outages_yaml
      end

      log_connection_attempt

      print_connection_status if offline?

      sleep POLLING_INTERVAL
    end
  rescue Interrupt, SignalException => exception
    print_outage_report

    if daemonized?
      alert
    end
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

  def show_daemon_summary
    return unless Daemon.running? && output_mode?

    @outages = YAML.load(File.read(yaml_file))

    @connection_status = @outages.any? && @outages.last.resolved? ? CONNECTION_STATUSES.online : CONNECTION_STATUSES.offline
    @connection_status = CONNECTION_STATUSES.online if @outages.none?

    print_connection_status

    print_outage_report if show_report?

    exit
  end

  def daemonize
    if Daemon.running? and @stop
      Daemon.stop!

      exit
    end

    return unless daemonized?

    if Daemon.running?
      puts "Daemon already running with PID #{Daemon.pid}"

      exit
    else
      Daemon.daemonize!
    end
  end

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
    rescue SocketError, Errno::EHOSTUNREACH, Errno::ENETUNREACH => e
      return CONNECTION_STATUSES.offline
    end
  end

  def uri
    URI("https://www.google.com")
  end

  def print_connection_status
    puts("\n#{Time.now.long_time_string}:") if daemonized?
    clear_screen unless output_mode?

    puts "Connection status: #{connection_status_string}".send(online? ? :green : :red)
    puts "Outages:           #{outages_count}, #{outage_duration_string}"

    return if current_outage.nil?

    puts "Current outage:    #{current_outage.long_summary}".yellow if offline?
    puts "Last outage:       #{current_outage.long_summary}" if online?
  end

  def clear_screen
    print "\e[2J\e[f" unless daemonized?
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

  def print_outage_report
    puts("\n#{Time.now.long_time_string}:") if daemonized?

    puts OutageReport.new(outages).run
  end

  def outage_duration_string
    total_duration_seconds.to_duration_string
  end

  def total_duration_seconds
    outages.sum(&:duration_seconds)
  end

  def write_outages_yaml
    File.open(yaml_file, "wb") do |file|
      file << YAML.dump(outages)
    end
  end

  def yaml_file
    "#{Daemon::BASE_DIR}/outages.yml"
  end

  def output_mode?
    show_report? || show_status?
  end
end

ConnectionMonitor.new(ARGV).start
