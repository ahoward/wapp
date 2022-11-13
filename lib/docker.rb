#! /usr/bin/env ruby
 
#
  require "fileutils"
  require "erb"
  require "shellwords"

#
  require_relative 'say.rb'
  require_relative 'senv.rb'

#
  script_f = File.expand_path(__FILE__)
  script_d = File.dirname(script_f)
  root_d = File.dirname(script_d)

#
  Dir.chdir(root_d)

# https://stackoverflow.com/questions/66662820/m1-docker-preview-and-keycloak-images-platform-linux-amd64-does-not-match-th
# also see ./docker/Dockerfile.erb !!!
  #ENV['DOCKER_BUILDKIT'] = '0'
  #ENV['COMPOSE_DOCKER_CLI_BUILD'] = '0'
  #ENV['DOCKER_DEFAULT_PLATFORM'] = 'linux/amd64/v8'

#
  empty_d = "./docker/empty/"

#
  CONFIG =
    {}

  BUILD =
    {}

  RUNTIME =
    {}

#
  CONFIG[:TARGET] = (
    ENV["TARGET"] || ENV["target"] || "development"
  )

  case
    when CONFIG[:TARGET] == "development"
      :ok
    when CONFIG[:TARGET] == "production"
      :ok
    else
      abort "TARGET != production|development"
  end

#
  ENV['SENV'] ||= CONFIG[:TARGET]

  Senv.load!

  CONFIG[:SENV] = (
    ENV['SENV']
  )

#
  CONFIG[:REPO] = (
    repo = (ENV['REPO'] || ENV['repo'] || Senv.environment.fetch('REPO')).to_s.strip
    (repo.size > 0 ? repo : abort('could not determine REPO'))
  )

#
  CONFIG[:SHA] = (
    sha = (ENV['SHA'] || ENV['sha'] || `git rev-parse HEAD 2>/dev/null`).to_s.strip
    (sha.size > 0 ? sha : abort('could not determine SHA'))
  )

  CONFIG[:DEV] = (
    (CONFIG[:SENV] == "development" ? "true" : "false")
  )

  CONFIG[:PORT] = (
    "8080"
  )

  CONFIG[:FRONTEND_PORT] = (
    "4000"
  )

  CONFIG[:BACKEND_PORT] = (
    "3000"
  )

#
  BUILD[:TARGET] =
    ENV["BUILD_TARGET"] || CONFIG[:TARGET]

  BUILD[:SENV] =
    ENV["BUILD_SENV"] || CONFIG[:SENV]

  BUILD[:PORT] =
    ENV["BUILD_PORT"] || CONFIG[:PORT]

  BUILD[:DEV] =
    ENV["BUILD_DEV"] || CONFIG[:DEV]

#
  case
    when BUILD[:DEV] == "true"
      BUILD[:SRC]    = empty_d
      BUILD[:MOUNT]  = "--mount 'type=bind,src=#{ root_d },dst=/app'"

    else
      BUILD[:SRC]    = "./"
      BUILD[:MOUNT]  = ""
  end

#
  BUILD[:ROOT] = File.expand_path(root_d)

  BUILD[:NAME] = "dojo4--#{ File.basename(root_d) }-#{ CONFIG[:TARGET] }-#{ CONFIG[:SENV] }"

  BUILD[:IMG] = "#{ BUILD[:NAME] }"

  BUILD[:TAG] = "#{ BUILD[:IMG] }"

#
  BUILD[:UID] = "1000"

  BUILD[:GID] = "1000"

#
  BUILD[:REPO] = (
    CONFIG[:REPO]
  )

  BUILD[:SHA] = (
    CONFIG[:SHA]
  )

#
  RUNTIME[:PORT] =
    CONFIG[:PORT]

  RUNTIME[:FRONTEND_PORT] =
    CONFIG[:FRONTEND_PORT]

  RUNTIME[:BACKEND_PORT] =
    CONFIG[:BACKEND_PORT]

  RUNTIME[:SENV] =
    CONFIG[:SENV]

  RUNTIME[:DEV] =
    CONFIG[:DEV]

  RUNTIME[:SHA] =
    CONFIG[:SHA]

#
  explode = proc do |config|
    hash, name = config.to_a.first
    hash.each do |key, value|
      const = "#{ name }_#{ key }"
      Object.const_set(const, value)
    end
  end

  explode[CONFIG => :CONFIG]
  explode[BUILD => :BUILD]
  explode[RUNTIME => :RUNTIME]

#
  module Docker
    def sys(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      lines = args.join("\n").strip.split(/[\n]+/)
      strings = lines.map{|line| line.strip}
      command = strings.join(" ")

      status = system(command) 

      unless status
        strategy = options[:error].to_s.to_sym

        case strategy
          when :abort
            abort("#{ command } #=> #{ $? }")
          when :ignore
            :noop
        end
      end

      status
    end

    def sys!(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:error] = :abort
      args.push(options)
      sys(*args, &block)
    end

    def args
      ARGV.map{|arg| Shellwords.escape("#{ arg }")}.join(" ")
    end

    def listen!
      path = File.join(BUILD_ROOT, "tmp/docker")
      glob = File.join(path, "**/**")

      Dir.glob(glob) do |entry|
        FileUtils.rm_rf(entry)
      end

      thread =
        Thread.new do
          loop do
            Dir.glob(glob) do |entry|
              dirname, basename = File.split(File.expand_path(entry))
              base, ext = basename.split(".", 2)

              cmd = base
              arg = IO.binread(entry).strip

              case cmd
                when /stop/
                  sys "./docker/stop --time 1"

                else
                  warn "[./docker/lib.rb] no such cmd #{ cmd }"
              end

              FileUtils.rm_f(entry)
            end

            sleep rand
          end
        end
    end

    class Logger
      def info(*args)
        Say.say(*args, :on_cyan)
      end

      def error(*args)
        Say.say(*args, :on_red)
      end

      def warn(*args)
        Say.say(*args, :on_magenta)
      end

      def success(*args)
        Say.say(*args, :on_green)
      end

      def puts(*args)
        ::Kernel.puts(*args)
      end

      def inspect(arg)
        ::Kernel.puts(arg.inspect)
      end
    end

    def log
      @log ||= Logger.new
    end

    def info!
      info = proc do |config|
        hash, name = config.to_a.first
        hash.each do |key, value|
          const = "#{ name }_#{ key }"
          Say.say("#{ const }=#{ value }", :color => :magenta)
        end
      end

      info[CONFIG => :CONFIG]
      info[BUILD => :BUILD]
      info[RUNTIME => :RUNTIME]
    end

    Docker.extend(Docker)
  end

#
  Docker.info! if __FILE__ == $0
