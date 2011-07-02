$:.unshift File.expand_path("../lib", __FILE__)
require "clink/version"

Gem::Specification.new do |gem|
  gem.name     = "clink"
  gem.version  = Clink::VERSION

  gem.author   = "David Dollar"
  gem.email    = "ddollar@gmail.com"
  gem.homepage = "http://github.com/ddollar/clink"
  gem.summary  = "Build a command line interface over HTTP"

  gem.description = gem.summary
  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }

  gem.add_dependency 'term-ansicolor', '~> 1.0.5'
  gem.add_dependency 'thor',           '>= 0.13.6'

  gem.add_development_dependency 'rake',   '~> 0.9.2'
  gem.add_development_dependency 'rcov',   '~> 0.9.8'
  gem.add_development_dependency 'rr',     '~> 1.0.2'
  gem.add_development_dependency 'rspec',  '~> 2.6.0'
end
