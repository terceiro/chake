# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chake/version'

Gem::Specification.new do |spec|
  spec.name          = "chake"
  spec.version       = Chake::VERSION
  spec.authors       = ["Antonio Terceiro"]
  spec.email         = ["terceiro@softwarelivre.org"]
  spec.summary       = %q{Simple host management with chef and rake. No chef server required.}
  spec.description   = %q{chake provides a set of rake tasks that you can use to manage any number of hosts via SSH. It doesn't require a chef server; all you need is a workstation from where you can SSH into all your hosts.}
  spec.homepage      = "https://gitlab.com/terceiro/chake"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec"

  spec.add_dependency "rake"
end
