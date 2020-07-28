# Connection Monitor

📢 Ruby script to monitor the Internet connection on a Mac with verbal notifications.

If your Internet connection is prone to dropping out, you can run this little script in the background, work on something that you can do offline, and wait for it to tell you when your connection is back online.

## Installation

Clone the repo:

    git clone git@github.com:beet/connection_monitor.git

## Usage

Run the script:

    ruby connection_monitor.rb

Once the connection is back online, it will use the system `say` command to tell you audibly.
