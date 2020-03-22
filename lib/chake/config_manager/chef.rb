require 'chake/config'

module Chake
  class ConfigManager
    class Chef < ConfigManager

      CONFIG = ENV['CHAKE_CHEF_CONFIG'] || 'config.rb'

      def converge
        node.run_as_root "sh -c 'rm -f #{node.path}/nodes/*.json && chef-solo -c #{node.path}/#{CONFIG} #{logging} -j #{json_config}'"
      end

      def apply(config)
        node.run_as_root "sh -c 'rm -f #{node.path}/nodes/*.json && chef-solo -c #{node.path}/#{CONFIG} #{logging} -j #{json_config} --override-runlist recipe[#{config}]'"
      end

      priority 99

      def self.accept?(node)
        true # this is the default, but after everything else
      end

      private

      def json_config
        parts = [node.path, Chake.tmpdir, node.hostname + '.json'].compact
        File.join(parts)
      end

      def logging
        node.silent && '-l fatal' || ''
      end
    end
  end
end
