require 'timeout'
require 'socket'

require_relative 'assassin'
require_relative 'senv'

module Util
  def nozombie(cmd, options = {})
    env = options.fetch(:env){ ENV.to_hash }

    Process.spawn(env, cmd).tap do |pid|
      Assassin.at_exit_kill(pid)
      Process.detach(pid)
    end
  end

  def serve!(cmd, options = {})
    root = File.expand_path(options.fetch(:root))
    port = options.fetch(:port)

    env = options.fetch(:env){ Hash.new }

    STDOUT.sync = true
    STDERR.sync = true

    Dir.chdir(root)

    Senv.load

    started = false
    reason = '?' 
    pid = nil

    envs = env.map{|kv| kv.join('=')}.join(' ')

    puts "#=> #{ root }: #{ envs } #{ cmd }"

    if Util.port_open?(port, :timeout => 2)
      pid = nozombie(cmd, :env => env)
      started = pid
    else
      reason = 'port used'
    end

    if started
      puts "#=> #{ root }: pid = #{ pid }"

      trap(:INT) do
        Process.wait(pid)
        exit
      end

      pid
    else
      abort "#=> #{ root }: failed to start, reason = #{ reason }"
    end
  end

  def find_free_port!(range = (3001 .. 4001))
    range.to_a.each do |port|
      if port_open?(port)
        return port
      end
    end

    nil
  end

  def port_open?(port, options = {})
    seconds = options[:timeout] || 1
    ip = options[:ip] || '0.0.0.0'

    Timeout::timeout(seconds) do
      begin
        TCPSocket.new(ip, port).close
        false
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        true
      rescue Object
        false
      end
    end
  rescue Timeout::Error
    false
  end

  def port_used?(port, options = {})
    hostname = options[:hostname] || options['hostname'] || 'localhost'
    server = TCPServer.new(hostname.to_s, port.to_s.to_i)
    server.close
    false
  rescue Errno::EADDRINUSE
    true
  end

  extend Util
end
