# Connection Monitor

📢 Ruby script to monitor the Internet connection on a Mac with verbal notifications and system alerts.

If your Internet connection is prone to dropping out, you can run this little script in the background, work on something that you can do offline, and wait for it to tell you when your connection is back online.

If it keeps dropping in and out, you can configure the verbal/visual notifications on the fly while it's running in the background so it's less annoying.

## Installation

Clone the repo:

    git clone git@github.com:beet/connection_monitor.git

## Usage

Run the script, printing outage information to the terminal:

    ./connection_monitor.rb [command] [options] [config]

Commands summary:

* `--stop` - stop the background daemon
* `--report` - display a detailed report of logged outages
* `--status` - show the current connection status
* `--config` - show the current configuration

Options summary:

* `--debug` - simulate sporadic outages
* `--daemonize` - run in the background as a daemon

Config summary:

* `--verbal-alerts=true|false` - turn verbal alerts on/off, can be issued while running as a daemon
* `--visual-alerts=true|false` - turn visual alerts on/off, can be issued while running as a daemon

### Running as a daemon

To run as a background daemon, logging outage information to `/usr/local/var/connection_monitor/stdout.log`:

    ./connection_monitor.rb --daemonize

Stop the daemon:

    ./connection_monitor.rb --stop

Display a report of outages while running as a daemon:

    ./connection_monitor.rb --report
    Connection status: Off-line
    Outages:           4, 00:32:34
    Current outage:    2021-05-07 15:11:02 - 2021-05-07 15:43:00, duration 00:31:58, 0 attempts

    Fri 07 May, 2021-05-07: out for 00:32:34

    * 15:10:17 - 15:10:35, duration 00:00:18, 6 attempts
    * 15:10:38 - 15:10:47, duration 00:00:09, 3 attempts
    * 15:10:50 - 15:10:59, duration 00:00:09, 3 attempts
    * 15:11:02 - 15:43:00, duration 00:31:58, 0 attempts

Display the current status while running as a daemon:

    ./connection_monitor.rb --status
    Connection status: Off-line
    Outages:           4, 00:33:11
    Current outage:    2021-05-07 15:11:02 - 2021-05-07 15:43:37, duration 00:32:35, 0 attempts

Turn notifications on/off while running as a daemon:

    ./connection_monitor.rb --verbal-alerts=false

## Configuration

Config changes can be made while running in the background, and are persisted to a config file in `/usr/local/var/connection_monitor/config.yml`

### Viewing the config

To display the current configuration:

    ./connection_monitor.rb --config             
    Config set to:

    verbal_alerts: false
    visual_alerts: true

### Alerts

The verbal and visual alerts can be configured with arguments that take truthy/falsey values.

    # Turn off verbal alerts
    ./connection_monitor.rb --verbal-alerts=false

    # Turn off visual alerts
    ./connection_monitor.rb --visual-alerts=false

    # No alerts, only output to the log file:
    ./connection_monitor.rb --verbal-alerts=false --visual-alerts=false
