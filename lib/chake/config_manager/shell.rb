require 'shellwords'
require 'chake/config'

module Chake
  class ConfigManager
    class Shell < ConfigManager

      def converge(silent = false)
        commands = node.data['shell'].join(' && ')
        run("sh -xec '#{commands}'", silent)
      end

      def apply(config, silent = false)
        run("sh -xec '#{config}'", silent)
      end

      def self.accept?(node)
        node.data.has_key?('shell')
      end

      private

      def logging(silent)
        silent ? " >/dev/null" : ''
      end

      def run(cmd, silent)
        node.run_as_root cmd + logging(silent)
      end
    end
  end
end
