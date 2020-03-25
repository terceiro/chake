require 'uri'
require 'etc'
require 'forwardable'

require 'chake/connection'
require 'chake/config_manager'

module Chake
  class Node
    extend Forwardable

    attr_reader :hostname
    attr_reader :port
    attr_reader :username
    attr_reader :remote_username
    attr_reader :data

    attr_accessor :silent

    def self.max_node_name_length
      @max_node_name_length ||= 0
    end

    class << self
      attr_writer :max_node_name_length
    end

    def initialize(hostname, data = {})
      uri = URI.parse(hostname)
      if !uri.host && ((!uri.scheme && uri.path) || (uri.scheme && uri.opaque))
        uri = URI.parse("ssh://#{hostname}")
      end
      uri.path = nil if uri.path && uri.path.empty?

      @connection_name = uri.scheme

      @hostname = uri.host
      @port = uri.port
      @username = uri.user || Etc.getpwuid.name
      @remote_username = uri.user
      @path = uri.path
      @data = data

      if @hostname.length > self.class.max_node_name_length
        self.class.max_node_name_length = @hostname.length
      end
    end

    def connection
      @connection ||= Chake::Connection.get(@connection_name).new(self)
    end

    def_delegators :connection, :run, :run_as_root, :run_shell, :rsync, :rsync_dest, :scp, :scp_dest, :skip?

    def config_manager
      @config_manager ||= Chake::ConfigManager.get(self)
    end

    def_delegators :config_manager, :converge, :apply, :path, :bootstrap_steps

    def path
      @path ||= config_manager.path
    end

    def log(msg)
      return if silent
      puts("%#{Node.max_node_name_length}<host>s: %<msg>s\n" % { host: hostname, msg: msg })
    end
  end
end
