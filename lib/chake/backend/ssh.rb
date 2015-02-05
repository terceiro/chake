module Chake

  class Backend

    class Ssh < Backend

      def rsync_dest
        [ssh_target, node.path + '/'].join(':')
      end

      def command_runner
        ['ssh', ssh_config, ssh_target].flatten.compact
      end

      private

      def ssh_config
        File.exist?('.ssh_config') && ['-F' '.ssh_config'] || []
      end

      def ssh_target
        [node.username, node.hostname].compact.join('@')
      end

    end

  end

end
