require 'chake/config'

module Chake
  class ConfigManager
    class Chef < ConfigManager

      CONFIG = ENV['CHAKE_CHEF_CONFIG'] || 'config.rb'

      def converge(silent = false)
        node.run_as_root "sh -c 'rm -f #{node.path}/nodes/*.json && chef-solo -c #{node.path}/#{CONFIG} #{logging(silent)} -j #{json_config}'"
      end

      def apply(config, silent = false)
        node.run_as_root "sh -c 'rm -f #{node.path}/nodes/*.json && chef-solo -c #{node.path}/#{CONFIG} #{logging(silent)} -j #{json_config} --override-runlist recipe[#{config}]'"
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

      def logging(silent)
        silent && '-l fatal' || ''
      end
    end
  end
end
