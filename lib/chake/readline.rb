require 'etc'
require 'readline'

module Chake

  module Readline

    class << self

      def history_file
        File.join(Dir.home, '.chake_history')
      end

      def init
        return if !File.exists?(history_file)
        File.readlines(history_file).each do |line|
          @last = line.strip
          ::Readline::HISTORY.push(@last)
        end
      end

      def finish
        history = ::Readline::HISTORY.map { |line| line }
        File.open(history_file, 'w') do |f|
          history.last(500).each do |line|
            f.puts(line)
          end
        end
      end

      def readline
        input = ::Readline.readline('$ ')
        if input && input.strip != '' && input != @last
          ::Readline::HISTORY.push(input)
        end
        input
      end

    end

  end

end

Chake::Readline.init
at_exit do
  Chake::Readline.finish
end
