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
        File.exist?(ssh_config_file) && ['-e', 'ssh -F ' + ssh_config_file ] || []
      end

      def ssh_config
        File.exist?(ssh_config_file) && ['-F', ssh_config_file] || []
      end

      def ssh_config_file
        @ssh_config_file ||= ENV.fetch('CHAKE_SSH_CONFIG', '.ssh_config')
      end

      def ssh_target
        [node.username, node.hostname].compact.join('@')
      end

    end

  end

end
