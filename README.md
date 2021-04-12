# Connection Monitor

📢 Ruby script to monitor the Internet connection on a Mac with verbal notifications and system alerts.

If your Internet connection is prone to dropping out, you can run this little script in the background, work on something that you can do offline, and wait for it to tell you when your connection is back online.

## Installation

Clone the repo:

    git clone git@github.com:beet/connection_monitor.git

## Usage

Run the script, printing outage information to the terminal:

    ./connection_monitor.rb

Run in debug mode to simulate outages randomly:

    ./connection_monitor.rb --debug

As a background daemon, logging outage information to `/usr/local/var/connection_monitor/stdout.log`:

    ./connection_monitor.rb --daemonize


Stop the daemon:

    ./connection_monitor.rb --stop

Display a report of outages _(while running as a daemon)_:

    ./connection_monitor.rb --reoprt
