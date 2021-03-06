begin
  require 'simplecov'
  SimpleCov.start do
    minimum_coverage 35.3
    track_files 'lib/**/*.rb'
    add_filter %r{^/spec/}
    add_filter %r{^/lib/chake/config_manager/skel/}
  end
rescue LoadError
  puts "W: simplecov not installed, we won't have a coverage report"
end

require 'chake/node'
require 'chake/connection'

require 'rspec/version'
if RSpec::Version::STRING < '2.14'
  puts 'Skipping tests, need RSpec >= 2.14'
  exit
end

shared_examples 'Chake::Connection' do |connection_class|
  let(:connection) { connection_class.new(node) }

  it('runs commands') do
    io = StringIO.new("line 1\n  line 2\n")
    expect(IO).to receive(:popen).with(connection.command_runner + ['/bin/sh'], 'w+', Hash).and_return(io)
    expect(io).to receive(:write).with('something').ordered
    expect(io).to receive(:close_write).ordered
    expect(node).to receive(:log).with('$ something')
    expect(node).to receive(:log).with('line 1')
    expect(node).to receive(:log).with('  line 2')
    connection.run('something')
  end

  it('runs as root') do
    expect(connection).to receive(:run).with('sudo something')
    connection.run_as_root('something')
  end

  it('does not use sudo if already root') do
    allow(connection.node).to receive(:remote_username).and_return('root')
    expect(connection).to receive(:run).with('something')
    connection.run_as_root('something')
  end
end

module Helpers
  def silence(stream)
    orig_stream = stream.clone
    begin
      File.open('/dev/null', 'w') do |f|
        stream.reopen(f)
        yield
      end
    ensure
      stream.reopen(orig_stream)
    end
  end
end

RSpec.configure do |c|
  c.include Helpers
end
