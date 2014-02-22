module Chake

  class Backend

    class Ssh < Backend

      def rsync_dest
        [ssh_target, node.path + '/'].join(':')
      end

      def command_runner
        ['ssh', ssh_target]
      end

      private

      def ssh_target
        [node.username, node.hostname].compact.join('@')
      end

    end

  end

end
