require 'shellwords'
require 'chake/config'

module Chake
  class ConfigManager
    class Shell < ConfigManager

      def converge(silent = false)
        commands = node.data['shell'].join(' && ')
        node.run_as_root sh(commands, silent)
      end

      def apply(config, silent = false)
        node.run_as_root sh(config, silent)
      end

      def self.accept?(node)
        node.data.has_key?('shell')
      end

      private

      def sh(command, silent)
        if silent
          "sh -ec '#{command}' >/dev/null"
        else
          "sh -xec '#{command}'"
        end
      end

      def run(cmd, silent)
        node.run_as_root cmd + logging(silent)
      end
    end
  end
end
