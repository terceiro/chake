require 'socket'

module Chake

  class Backend

    class Local < Backend

      def command_runner
        ['sh', '-c']
      end

      def skip?
        node.hostname != Socket.gethostname
      end

    end

  end

end
