#!/usr/bin/env ruby
require "fileutils"
require "yaml"

Dir["#{__dir__}/lib/**/*.rb"].each do |file|
  require_relative file
end

class ConnectionMonitor
  POLLING_INTERVAL = 3
  DEFAULT_CONFIG = {
    verbal_alerts: true,
    visual_alerts: true,
  }

  include PredicateAttributes
  using ColourizedStrings
  using TimeFormats

  attr_reader :args, :outages, :connection_status, :config

  def initialize(args)
    @args = args
    @outages = []
    @connection_status = ConnectionStatus::Null.new

    # Start command options:
    @debug_mode = args.include?("--debug")
    @daemonized = args.include?("--daemonize")

    # Commands: (default is start)
    @stop = args.include?("--stop")
    @show_report = args.include?("--report")
    @show_status = args.include?("--status")
    @show_config = args.include?("--config")

    @config = Config.new(defaults: DEFAULT_CONFIG, base_dir: Daemon::BASE_DIR)
  end

  def run
    return stop if stop?
    return report if show_report?
    return status if show_status?
    return config.show if show_config?

    config.update(args)

    start? ? start : tail_logs
  end

  private

  # Start the main monitor loop. Will daemonize if started with the --daemonize
  # option.
  def start
    daemonize

    while true
      config.read

      current_connection_status = get_connection_status

      if current_connection_status != connection_status
        if current_connection_status.online?
          close_current_outage
        end

        if current_connection_status.offline?
          open_new_outage(current_connection_status)
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

  def start?
    !stop? && !show_report? && !show_status? && !Daemon.running?
  end

  def stop
    if Daemon.running? and stop?
      Daemon.stop!
    end
  end

  def report
    load_outages

    print_connection_status

    print_outage_report
  end

  def status
    load_outages

    print_connection_status
  end

  def load_outages
    @outages = YAML.load(File.read(yaml_file))

    @connection_status = @outages.any? && @outages.last.resolved? ? ConnectionStatus::Online.new : ConnectionStatus::Offline.new
    @connection_status = ConnectionStatus::Online.new if @outages.none?
  end

  def connection_status_string
    online? ? "Online" : "Off-line"
  end

  def online?
    connection_status.online?
  end

  def offline?
    connection_status.offline?
  end

  def daemonize
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
      return rand(100) > 75 ? ConnectionStatus::Online.new : ConnectionStatus::Offline.new
    end

    ConnectionStatus.new
  end

  def uri
    URI("https://www.google.com")
  end

  def print_connection_status
    puts("\n#{Time.now.long_time_string}:") if daemonized?
    clear_screen unless output_mode?

    puts "Connection status: #{connection_status_string.send(online? ? :green : :red)}"
    puts "Outages:           #{outages_count}, #{outage_duration_string}"
    puts "Daemon:            #{Daemon.running? ? "Running".green : "Not running".red}"

    return if current_outage.nil?

    puts "Current outage:    #{current_outage.long_summary}".yellow if offline?
    puts "Last outage:       #{current_outage.long_summary}" if online?
  end

  def clear_screen
    print "\e[2J\e[f" unless daemonized?
  end

  def alert
    verbal_alert

    visual_alert
  end

  def verbal_alert
    return unless config.verbal_alerts?

    Process.spawn(%(osascript -e 'say "Internet connection #{connection_status_string}"'))
  end

  def visual_alert
    return unless config.visual_alerts?

    Process.spawn(%(osascript -e 'display notification "#{outages_count} outages" with title "Internet Connection Monitor" subtitle "#{connection_status_string}" sound name "Submarine"'))
  end

  def open_new_outage(connection_status)
    @outages << ConnectionOutage.new(connection_status)
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
    File.open(yaml_file, "ab") do |file|
      file << YAML.dump(outages)
    end
  end

  def yaml_file
    "#{Daemon::BASE_DIR}/outages.yml"
  end

  def output_mode?
    show_report? || show_status?
  end

  def tail_logs
    while true
      status

      sleep POLLING_INTERVAL
    end
  rescue Interrupt, SignalException => exception
    print_outage_report
  end
end

ConnectionMonitor.new(ARGV).run
