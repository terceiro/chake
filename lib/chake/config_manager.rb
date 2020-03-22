module Chake
  class ConfigManager

    attr_reader :node

    def initialize(node)
      @node = node
    end

    def converge
    end

    def apply(config)
    end

    def path
      "/var/tmp/#{name}.#{node.username}"
    end

    def name
      self.class.short_name
    end

    def to_s
      name
    end

    def bootstrap_steps
      base = File.join(File.absolute_path(File.dirname(__FILE__)), 'bootstrap')
      steps = Dir[File.join(base, '*.sh')] + Dir[File.join(base, name, '*.sh')]
      steps.sort_by { |f| File.basename(f) }
    end

    def self.short_name
      name.split('::').last.downcase
    end

    def self.priority(n = nil)
      @priority ||= n || 50
    end

    def self.inherited(klass)
      @subclasses ||= []
      @subclasses << klass
    end

    def self.get(node)
      available = @subclasses.sort_by(&:priority)
      manager = available.find { |c| c.short_name == node.data["config_manager"] }
      manager ||= available.find { |c| c.accept?(node) }
      raise ArgumentError.new("Can't find configuration manager class for node #{node.hostname}. Available: #{available}.join(', ')}") unless manager
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
