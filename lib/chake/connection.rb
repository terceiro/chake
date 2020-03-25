module Chake
  class Connection < Struct.new(:node)
    class CommandFailed < RuntimeError
    end

    def scp
      ['scp']
    end

    def scp_dest
      ''
    end

    def rsync
      ['rsync']
    end

    def rsync_dest
      node.path + '/'
    end

    def run(cmd)
      printf("%#{Node.max_node_name_length}s: $ %s\n", node.hostname, cmd) unless node.silent
      io = IO.popen(command_runner + ['/bin/sh'], mode = 'w+', err: %i[child out])
      io.write(cmd)
      io.close_write
      io.each_line do |line|
        printf "%#{Node.max_node_name_length}s: %s\n", node.hostname, line.strip
      end
      io.close
      if $CHILD_STATUS
        status = $CHILD_STATUS.exitstatus
        if status != 0
          raise CommandFailed, [node.hostname, format('FAILED with exit status %d', status)].join(': ')
        end
      end
    end

    def run_shell
      system(*shell_command)
    end

    def run_as_root(cmd)
      if node.remote_username == 'root'
        run(cmd)
      else
        run('sudo ' + cmd)
      end
    end

    def to_s
      self.class.connection_name
    end

    def skip?
      false
    end

    def self.connection_name
      name.split('::').last.downcase
    end

    def self.inherited(subclass)
      @connections ||= []
      @connections << subclass
    end

    def self.get(name)
      connection = @connections.find { |b| b.connection_name == name }
      raise ArgumentError, "Invalid connection name: #{name}" unless connection
      connection
    end
  end
end

require 'chake/connection/ssh'
require 'chake/connection/local'
