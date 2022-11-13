require 'sinatra'
require 'yaml'

#SOCKET_PATH = File.expand_path('tmp/app.sock')

class App < Sinatra::Base
  set :server, :puma
  #set :bind, SOCKET_PATH

  get %r`/.*` do
    "backend\n\n\n#{ ENV.to_hash.sort.to_yaml }"
  end
end

BEGIN {
  ENV['BUNDLE_GEMFILE'] ||= File.expand_path('./Gemfile', __dir__)
  require 'bundler/setup'
}

if __FILE__ == $0
  App.run!
end

