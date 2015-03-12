require 'uri'
require 'etc'
require 'forwardable'

require 'chake/backend'

module Chake

  class Node

    extend Forwardable

    attr_reader :hostname
    attr_reader :username
    attr_reader :remote_username
    attr_reader :path
    attr_reader :data

    def self.max_node_name_length
      @max_node_name_length ||= 0
    end
    def self.max_node_name_length=(value)
      @max_node_name_length = value
    end

    def initialize(hostname, data = {})
      uri = URI.parse(hostname)
      if !uri.scheme && !uri.host && uri.path
        uri = URI.parse("ssh://#{hostname}")
      end
      if uri.path.empty?
        uri.path = nil
      end

      @backend_name = uri.scheme

      @hostname = uri.host
      @username = uri.user || Etc.getpwuid.name
      @remote_username = uri.user
      @path = uri.path || "/var/tmp/chef.#{username}"
      @data = data

      if @hostname.length > self.class.max_node_name_length
        self.class.max_node_name_length = @hostname.length
      end
    end

    def backend
      @backend ||= Chake::Backend.get(@backend_name).new(self)
    end

    def_delegators :backend, :run, :run_as_root, :rsync, :rsync_dest, :scp, :scp_dest, :skip?

  end

end

