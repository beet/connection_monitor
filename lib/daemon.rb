# Taken from https://gist.github.com/mynameisrufus/1372491/b76b60fb1842bf0507f47869ab19ad50a045b214
class Daemon
  DAEMON_NAME = "connection_monitor"
  BASE_DIR = "/usr/local/var/#{DAEMON_NAME}"

  class << self
    def daemonize!
      create_working_dir

      double_fork

      kill_process

      write_pid

      change_working_directory

      redirect_output
    end

    def running?
      begin
        Process.getpgid(pid)

        true
      rescue Errno::ESRCH, Errno::ENOENT
        false
      end
    end

    def pid
      open(filename("pid")).read.strip.to_i
    end

    def stop!
      kill_process

      cleanup
    end

    def cleanup
      File.delete(filename("pid"))
    end

    private

    def create_working_dir
      FileUtils.mkdir_p(BASE_DIR)
    end

    def double_fork
      raise 'First fork failed' if (@pid = fork) == -1
      exit unless @pid.nil?

      Process.setsid

      raise 'Second fork failed' if (@pid = fork) == -1
      exit unless @pid.nil?
    end

    # Try and read the existing pid from the pid file and signal HUP to
    # process.
    def kill_process
      Process.kill("HUP", pid)
    rescue TypeError
      $stdout.puts "#{pidfile} was empty: TypeError"
    rescue Errno::ENOENT
      # $stdout.puts "#{pidfile} did not exist: Errno::ENOENT"
    rescue Errno::ESRCH
      $stdout.puts "The process #{opid} did not exist: Errno::ESRCH"
    rescue Errno::EPERM
      raise "Lack of privileges to manage the process #{opid}: Errno::EPERM"
    rescue ::Exception => e
      raise "While signaling the PID, unexpected #{e.class}: #{e}"
    end

    # Attempts to write the pid of the forked process to the pid file.
    # Kills process if write unsuccesfull.
    def write_pid
      File.open(filename("pid"), "w") do |f|
        f.write(Process.pid)
        f.close
      end

      $stdout.puts "#{DAEMON_NAME} running with pid: #{Process.pid}"
    rescue ::Exception => e
      raise "While writing the PID to file, unexpected #{e.class}: #{e}"
    end

    def change_working_directory
      Dir.chdir '/'
      File.umask 0000
    end

    # Redirect file descriptors inherited from the parent.
    def redirect_output
      $stdin.reopen '/dev/null'
      $stdout.reopen File.new(filename("stdout.log"), "a")
      $stderr.reopen File.new(filename("stderr.log"), "a")
      $stdout.sync = $stderr.sync = true
    end

    def filename(extension)
      "#{BASE_DIR}/#{extension}"
    end
  end
end