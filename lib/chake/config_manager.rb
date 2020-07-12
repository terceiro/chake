require 'pathname'

module Chake
  class ConfigManager
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def converge; end

    def apply(config); end

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

    def needs_bootstrap?
      true
    end

    def needs_upload?
      true
    end

    def self.short_name
      name.split('::').last.downcase
    end

    def self.priority(new_prioriry = nil)
      @priority ||= new_prioriry || 50
    end

    def self.inherited(klass)
      @subclasses ||= []
      @subclasses << klass
    end

    def self.get(node)
      available = @subclasses.sort_by(&:priority)
      manager = available.find { |c| c.short_name == node.data['config_manager'] }
      manager ||= available.find { |c| c.accept?(node) }
      raise ArgumentError, "Can't find configuration manager class for node #{node.hostname}. Available: #{available}.join(', ')}" unless manager

      manager.new(node)
    end

    def self.accept?(_node)
      false
    end

    def self.all
      @subclasses
    end

    def self.init
      skel = Pathname(__FILE__).parent / 'config_manager' / 'skel' / short_name
      skel.glob('**/*').each do |source|
        target = source.relative_path_from(skel)
        if target.exist?
          puts "exists: #{target}"
        else
          if source.directory?
            FileUtils.mkdir_p target
          else
            FileUtils.cp source, target
          end
          puts "create: #{target}"
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/config_manager/*.rb'].sort.each do |f|
  require f
end
