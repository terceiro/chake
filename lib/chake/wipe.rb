require 'singleton'

module Chake
  class Wipe
    include Singleton

    if system('which', 'wipe', out: '/dev/null', err: :out)
      def wipe(file)
        system('wipe', '-rfs', file)
      end
    else
      warn 'W: please install the \`wipe\` program for secure deletion, falling back to unlink(2)'
      def wipe(file)
        File.unlink(file)
      end
    end
  end
end
