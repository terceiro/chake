begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  puts "W: simplecov not installed, we won't have a coverage report"
end

require 'chake/node'
require 'chake/backend'

require 'rspec/version'
if RSpec::Version::STRING < '2.14'
  puts "Skipping tests, need RSpec >= 2.14"
  exit
end

shared_examples "Chake::Backend" do |backend_class|

  let(:backend) { backend_class.new(node) }

  it('runs commands') do
    io = StringIO.new("line 1\n  line 2\n")
    expect(IO).to receive(:popen).with(backend.command_runner + ['/bin/sh'], mode='w+', Hash).and_return(io)
    expect(io).to receive(:write).with('something').ordered
    expect(io).to receive(:close_write).ordered
    expect(backend).to receive(:printf).with(anything, "myhost", "something")
    expect(backend).to receive(:printf).with(anything, "myhost", "line 1")
    expect(backend).to receive(:printf).with(anything, "myhost", "  line 2")
    backend.run('something')
  end

  it('runs as root') do
    expect(backend).to receive(:run).with('sudo something')
    backend.run_as_root('something')
  end

  it('does not use sudo if already root') do
    allow(backend.node).to receive(:remote_username).and_return('root')
    expect(backend).to receive(:run).with('something')
    backend.run_as_root('something')
  end

end

