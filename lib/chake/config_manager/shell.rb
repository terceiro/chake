require 'shellwords'
require 'chake/config'

module Chake
  class ConfigManager
    class Shell < ConfigManager
      def converge
        commands = node.data['shell'].join(' && ')
        node.run_as_root sh(commands)
      end

      def apply(config)
        node.run_as_root sh(config)
      end

      def self.accept?(node)
        node.data.key?('shell')
      end

      private

      def sh(command)
        if node.path
          command = "cd #{node.path} && " + command
        end
        if node.silent
          "sh -ec '#{command}' >/dev/null"
        else
          "sh -xec '#{command}'"
        end
      end
    end
  end
end
