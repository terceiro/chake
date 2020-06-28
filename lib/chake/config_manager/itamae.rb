require 'shellwords'
require 'chake/config'
require 'chake/tmpdir'

module Chake
  class ConfigManager
    class Itamae < ConfigManager
      def converge
        run_itamae(*node.data['itamae'])
      end

      def apply(config)
        run_itamae(config)
      end

      def needs_bootstrap?
        false
      end

      def needs_upload?
        false
      end

      def self.accept?(node)
        node.data.key?('itamae')
      end

      private

      def run_itamae(*recipes)
        cmd = ['itamae']
        case node.connection
        when Chake::Connection::Ssh
          cmd << 'ssh' << "--user=#{node.username}" << "--host=#{node.hostname}"
          cmd += ssh_config
        when Chake::Connection::Local
          cmd << 'local'
        else
          raise NotImplementedError, "Connection type #{node.connection.class} not supported for itamee"
        end
        cmd << "--node-json=#{json_config}"
        cmd += recipes
        node.log("$ #{cmd.join(' ')}")
        io = IO.popen(cmd, 'r', err: %i[child out])
        node.connection.read_output(io)
      end

      def json_config
        File.join(Chake.tmpdir, "#{node.hostname}.json")
      end

      def ssh_config
        ssh_config = node.connection.send(:ssh_config_file) # FIXME
        File.exist?(ssh_config) ? ["--ssh-config=#{ssh_config}"] : []
      end
    end
  end
end
