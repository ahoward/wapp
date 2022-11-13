require 'sinatra'
require 'yaml'

get %r`/_/ctl/restart` do
  status = system('git pull && ./script/dependencies && ./script/build && ./script/server restart')
  status.inspect
end

get %r`/.*` do
  "backend\n\n\n#{ ENV.to_hash.sort.to_yaml }"
end

BEGIN {
  ENV['BUNDLE_GEMFILE'] ||= File.expand_path('./Gemfile', __dir__)
  require 'bundler/setup'
}

