module Chake

  class Backend < Struct.new(:node)

    def rsync_dest
      node.path + '/'
    end

    def run(cmd)
      IO.popen(command_runner + [cmd]).lines.each do |line|
        puts [node.hostname, line.strip].join(': ')
      end
    end

    def run_as_root(cmd)
      if node.username == 'root'
        run(cmd)
      else
        run('sudo ' + cmd)
      end
    end

    def to_s
      self.class.backend_name
    end

    def self.backend_name
      name.split("::").last.downcase
    end

    def self.inherited(subclass)
      @backends ||= []
      @backends << subclass
    end

    def self.get(name)
      backend = @backends.find { |b| b.backend_name == name }
      backend || raise(ArgumentError.new("Invalid backend name: #{name}"))
    end

  end

end

require 'chake/backend/ssh'
require 'chake/backend/local'
