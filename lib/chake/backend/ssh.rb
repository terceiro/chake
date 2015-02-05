module Chake

  class Backend

    class Ssh < Backend

      def scp
        ['scp', ssh_config].flatten.compact
      end

      def scp_dest
        ssh_target + ':'
      end

      def rsync
        ['rsync', rsync_ssh].flatten.compact
      end

      def rsync_dest
        [ssh_target, node.path + '/'].join(':')
      end

      def command_runner
        ['ssh', ssh_config, ssh_target].flatten.compact
      end

      private

      def rsync_ssh
        File.exist?('.ssh_config') && ['-e', 'ssh -F .ssh_config'] || []
      end

      def ssh_config
        File.exist?('.ssh_config') && ['-F' '.ssh_config'] || []
      end

      def ssh_target
        [node.username, node.hostname].compact.join('@')
      end

    end

  end

end
