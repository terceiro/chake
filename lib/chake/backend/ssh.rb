module Chake

  module Backend

    class Ssh < Struct.new(:node)

      def rsync_dest
        [ssh_target, node.path + '/'].join(':')
      end

      def run(cmd)
        IO.popen(['ssh', ssh_target, cmd]).lines.each do |line|
          puts [node.hostname, line.strip].join(": ")
        end
      end

      private

      def ssh_target
        [node.username, node.hostname].compact.join('@')
      end

    end

  end

end
