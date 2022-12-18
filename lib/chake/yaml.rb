require 'yaml'

module Chake
  module YAML
    def self.load_file(filename)
      if RUBY_VERSION >= '3.1'
        ::YAML.load_file(filename, aliases: true)
      else
        ::YAML.load_file(filename)
      end
    end
  end
end
