module Chake
  class Connection
    class Ssh < Connection
      def scp
        ['scp', ssh_config, scp_options].flatten.compact
      end

      def scp_dest
        "#{ssh_target}:"
      end

      def rsync
        [ssh_prefix, 'rsync', rsync_ssh].flatten.compact
      end

      def rsync_dest
        [ssh_target, "#{node.path}/"].join(':')
      end

      def command_runner
        [ssh_prefix, 'ssh', ssh_config, ssh_options, ssh_target].flatten.compact
      end

      def shell_command
        command_runner
      end

      private

      def rsync_ssh
        @rsync_ssh ||=
          begin
            ssh_command = 'ssh'
            if File.exist?(ssh_config_file)
              ssh_command += " -F #{ssh_config_file}"
            end
            ssh_command += " -p #{node.port}" if node.port
            if ssh_command == 'ssh'
              []
            else
              ['-e', ssh_command]
            end
          end
      end

      def ssh_config
        File.exist?(ssh_config_file) && ['-F', ssh_config_file] || []
      end

      def ssh_config_file
        @ssh_config_file ||= ENV.fetch('CHAKE_SSH_CONFIG', '.ssh_config')
      end

      def ssh_prefix
        @ssh_prefix ||= ENV.fetch('CHAKE_SSH_PREFIX', '').split
      end

      def ssh_target
        [node.remote_username, node.hostname].compact.join('@')
      end

      def ssh_options
        node.port && ['-p', node.port.to_s] || []
      end

      def scp_options
        node.port && ['-P', node.port.to_s] || []
      end
    end
  end
end
