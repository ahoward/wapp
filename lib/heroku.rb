require 'pathname'
require 'yaml'

require_relative '../lib/map.rb'

module Heroku
  def default_app
    targets = Map.for(Heroku.targets)

    marked_as_default = proc do |key|
      k = (key[0 .. -2] + %w[ default ])
      targets.get(*k).to_s =~ /\Atrue\z/i
    end

    app = nil

    targets.depth_first_each do |key, val|
      if key.last == 'app'
        if(targets.size == 1 or marked_as_default[key]) 
          app = val
          break
        end
      end
    end

    app
  end

  def targets
    Map.for(config['targets'] || {})
  end

  def path_for(*args)
    args.flatten.join('.').scan(%r`[^\.]+`).join('.')
  end

  def targets_for(*args)
    path = Heroku.path_for(*args) 
    key = path.split('.')

    value = Heroku.targets.get(*key)

    target_for = proc do |hash|
      Map.for(hash.dup).update(:path => path)
    end

    case
      when value.is_a?(Hash) && value.has_key?('app')
        targets = []
        target = target_for[value] 
        targets.push(target)

      when value.is_a?(Hash)
        targets =
          value.keys.map do |subkey|
            subpath = "#{ path }.#{ subkey }"
            Heroku.targets_for(subpath)
          end.flatten

      else
        abort "no path=#{ path.inspect } found in #{ Heroku.config_yml }"
    end
  end

  def repo_for(heroku_app)
    "https://git.heroku.com/#{ heroku_app }.git"
  end

  def config(*args, &block)
    @config ||= load_config

    unless args.empty?
      key = args.flatten
    end

    if block
      before = @config.to_yaml
      begin
        block.call(@config)
      ensure
        after = @config.to_yaml
        IO.binwrite(config_yml, after) if before != after
      end
    else
      @config
    end
  end

  def load_config
    YAML.load(IO.binread(config_yml))
  end

  def load_config!
    @config = YAML.load(IO.binread(config_yml))
  end

  def config_yml
    candidates = []
    
    paths = %w[ config/heroku.yaml config/heroku.yml ]

    paths.each do |path|
      glob = root_d(path)
      candidates.push(*Dir.glob(glob))
    end
    
    case candidates.size
      when 0
        abort "no config/heroku.{yaml,yml} found!"
      when 1
        config_yml = candidates.first
      else
        abort "multiple configs found in #{ candidates.inspect }"
    end

    config_yml
  end

  def root_d=(path)
    @root_d = File.expand_path(path.to_s) 
  end

  def root_d(*path)
    @root_d ||= File.dirname(lib_d) 
    path.size == 0 ? @root_d : File.join(@root_d, *path.flatten.compact)
  end

  def lib_d
    Pathname.new(__FILE__).realpath.dirname.to_s
  end

  extend(Heroku)
end
