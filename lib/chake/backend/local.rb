module Chake

  module Backend

    class Local < Struct.new(:node)

      def rsync_dest
        node.path + '/'
      end

      def run(cmd)
        IO.popen(['sh', '-c', cmd]).lines.each do |line|
          puts [node.hostname, line.strip].join(': ')
        end
      end

    end

  end

end
