require 'uri'
require 'etc'
require 'forwardable'

require 'chake/connection'

module Chake

  class Node

    extend Forwardable

    attr_reader :hostname
    attr_reader :port
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
      if !uri.host && ((!uri.scheme && uri.path) || (uri.scheme && uri.opaque))
        uri = URI.parse("ssh://#{hostname}")
      end
      if uri.path && uri.path.empty?
        uri.path = nil
      end

      @connection_name = uri.scheme

      @hostname = uri.host
      @port = uri.port
      @username = uri.user || Etc.getpwuid.name
      @remote_username = uri.user
      @path = uri.path || "/var/tmp/chef.#{username}"
      @data = data

      if @hostname.length > self.class.max_node_name_length
        self.class.max_node_name_length = @hostname.length
      end
    end

    def connection
      @connection ||= Chake::Connection.get(@connection_name).new(self)
    end

    def_delegators :connection, :run, :run_as_root, :run_shell, :rsync, :rsync_dest, :scp, :scp_dest, :skip?

  end

end

