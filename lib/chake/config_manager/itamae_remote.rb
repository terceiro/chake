require 'shellwords'
require 'chake/config'
require 'chake/tmpdir'

module Chake
  class ConfigManager
    class ItamaeRemote < ConfigManager
      def converge
        run_itamae(*node.data['itamae-remote'])
      end

      def apply(config)
        run_itamae(config)
      end

      def needs_upload?
        true
      end

      def self.accept?(node)
        node.data.key?('itamae-remote')
      end

      private

      def run_itamae(*recipes)
        cmd = ['itamae', 'local', "--node-json=#{json_config}"]
        if node.silent
          cmd << '--log-level=warn'
        end
        cmd += recipes.map { |r| File.join(node.path, r) }
        node.run_as_root(Shellwords.join(cmd))
      end

      def json_config
        File.join(node.path, Chake.tmpdir, "#{node.hostname}.json")
      end
    end
  end
end
