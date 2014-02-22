require 'uri'
require 'etc'
require 'forwardable'

require 'chake/backend'

module Chake

  class Node

    extend Forwardable

    attr_reader :hostname
    attr_reader :username
    attr_reader :path
    attr_reader :data

    def initialize(hostname, data = {})
      uri = URI.parse(hostname)
      if !uri.scheme && !uri.host && uri.path
        uri = URI.parse("ssh://#{hostname}")
      end
      if uri.path.empty?
        uri.path = nil
      end

      @backend_name = uri.scheme

      @hostname = uri.hostname
      @username = uri.user || Etc.getpwuid.name
      @path = uri.path || "/tmp/chef.#{username}"
      @data = data
    end

    def backend
      @backend ||= Chake::Backend.get(@backend_name).new(self)
    end

    def_delegators :backend, :run, :run_as_root, :rsync_dest

  end

end

