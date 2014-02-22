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

  end

end

require 'chake/backend/ssh'
require 'chake/backend/local'
