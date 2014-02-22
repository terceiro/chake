require 'chake/node'
require 'chake/backend'


shared_examples "Chake::Backend" do |backend_class|

  let(:backend) { backend_class.new(node) }

  it('runs commands') do
    io = StringIO.new("line 1\nline 2\n")
    IO.should_receive(:popen).with(backend.command_runner + ['something']).and_return(io)
    backend.should_receive(:puts).with("myhost: line 1")
    backend.should_receive(:puts).with("myhost: line 2")
    backend.run('something')
  end

  it('runs as root') do
    backend.should_receive(:run).with('sudo something')
    backend.run_as_root('something')
  end

  it('does not use sudo if already root') do
    backend.node.stub(:username).and_return('root')
    backend.should_receive(:run).with('something')
    backend.run_as_root('something')
  end

end

