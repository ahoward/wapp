# global ENV vars 
#
  ENV['BACKEND_PORT'] ||= '4000'
  ENV['FRONTEND_PORT'] ||= '3000'

  ENV['PROXY_PORT'] ||= (ENV['PORT'] || '8080')
  ENV['PORT'] = ENV['PROXY_PORT']

  ENV['A'] = 'one'
  ENV['B'] = 'two'
  ENV['C'] = 'three'

# PATH 
#
  path = ENV['PATH']

  # include ruby's path
  ruby = `which ruby`.strip
  bindir, bin = File.split(ruby)
  path = [bindir, path].join(':')

  # include nodes's path
  node = `which node`.strip
  bindir, bin = File.split(node)
  path = [bindir, path].join(':')

  # local node clis
  path = ['./node_modules/.bin', path].join(':')

  # local clis
  path = ['./bin', path].join(':')

  ENV['PATH'] = path
