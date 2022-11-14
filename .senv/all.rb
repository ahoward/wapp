# global ENV vars 
#
  ENV['REPO'] ||= 'https://github.com/ahoward/dynamic'

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

  ruby = `which ruby`.strip
  bindir, bin = File.split(ruby)
  path = [bindir, path].join(':')

  node = `which node`.strip
  bindir, bin = File.split(node)
  path = [bindir, path].join(':')

  path = ['./node_modules/.bin', path].join(':')

  path = ['./bin', path].join(':')

  ENV['PATH'] = path
