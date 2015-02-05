module Chake

  class Backend < Struct.new(:node)

    class CommandFailed < Exception
    end

    def rsync_dest
      node.path + '/'
    end

    def run(cmd)
      puts "#{node.hostname}: $ #{cmd}"
      output = IO.popen(command_runner + [cmd])
      output.each_line do |line|
        puts [node.hostname, line.strip].join(': ')
      end
      output.close
      if $?
        status = $?.exitstatus
        if status != 0
          raise CommandFailed.new([node.hostname, 'FAILED with exit status %d' % status].join(': '))
        end
      end
    end

    def run_as_root(cmd)
      if node.username == 'root'
        run(cmd)
      else
        run('sudo sh -c "' + cmd + '"')
      end
    end

    def to_s
      self.class.backend_name
    end

    def skip?
      false
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
