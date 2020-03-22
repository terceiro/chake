require 'socket'

module Chake

  class Connection

    class Local < Connection

      def command_runner
        ['sh', '-c']
      end

      def shell_command
        ENV.fetch('SHELL', Etc.getpwuid.shell)
      end

      def skip?
        node.hostname != Socket.gethostname
      end

    end

  end

end
