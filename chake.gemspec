lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chake/version'

Gem::Specification.new do |spec|
  spec.name          = 'chake'
  spec.version       = Chake::VERSION
  spec.authors       = ['Antonio Terceiro']
  spec.email         = ['terceiro@softwarelivre.org']
  spec.summary       = 'serverless configuration management tool for chef'
  spec.description   = "chake allows one to manage a number of hosts via SSH by combining chef (solo) and rake. It doesn't require a chef server; all you need is a workstation from where you can SSH into all your hosts. chake automates copying the configuration management repository to the target host (including managing encrypted files), running chef on them, and running arbitrary commands on the hosts."
  spec.homepage      = 'https://gitlab.com/terceiro/chake'
  spec.license       = 'MIT'

  spec.files         = File.read('.manifest').split("\n") + ['.manifest']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'ronn-ng'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'

  spec.add_dependency 'rake'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
