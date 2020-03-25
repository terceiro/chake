require 'etc'
require 'readline'

require 'chake/tmpdir'

module Chake
  class Readline
    class << self
      def history_file
        raise NotImplementedError
      end

      def history
        @history ||= []
      end

      def prompt
        raise NotImplementedError
      end

      def init
        return unless File.exist?(history_file)
        @history = File.readlines(history_file).map(&:strip)
      end

      def finish
        return if !File.writable?(File.dirname(history_file)) || history.empty?
        File.open(history_file, 'w') do |f|
          history.last(500).each do |line|
            f.puts(line)
          end
        end
      end

      def readline
        ::Readline::HISTORY.clear
        history.each do |cmd|
          ::Readline::HISTORY.push(cmd)
        end
        input = ::Readline.readline(prompt)
        history.push(input) if input && input.strip != '' && input != @last
        input
      end
    end

    class Commands < Readline
      def self.history_file
        File.join(Chake.tmpdir, '.commands_history')
      end

      def self.prompt
        '$ '
      end
    end

    class Recipes < Readline
      def self.history_file
        File.join(Chake.tmpdir, '.recipes_history')
      end

      def self.prompt
        '> '
      end
    end
  end
end

Chake::Readline.constants.each do |subclass|
  subclass = Chake::Readline.const_get(subclass)
  subclass.init
  at_exit do
    subclass.finish
  end
end
