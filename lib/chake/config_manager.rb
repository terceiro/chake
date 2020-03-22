module Chake
  class ConfigManager

    attr_reader :node

    def initialize(node)
      @node = node
    end

    def converge(silent = false)
    end

    def apply(config, silent = false)
    end

    def path
      "/var/tmp/#{name}.#{node.username}"
    end

    def name
      self.class.name.split('::').last.downcase
    end

    def self.inherited(klass)
      @subclasses ||= []
      @subclasses << klass
    end

    def self.get(node)
      manager = @subclasses.find { |c| c.accept?(node) }
      raise ArgumentError.new("Can't find configuration manager class for node #{node.hostname}. Available: #{@subclasses.map(&:name).join(', ')}") unless manager
      manager.new(node)
    end

    def self.accept?(node)
      false
    end

  end
end

Dir[File.dirname(__FILE__) + '/config_manager/*.rb'].each do |f|
  require f
end
