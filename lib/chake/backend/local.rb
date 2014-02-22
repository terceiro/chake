module Chake

  class Backend

    class Local < Backend

      def command_runner
        ['sh', '-c']
      end

    end

  end

end
