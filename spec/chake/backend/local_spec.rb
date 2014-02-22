require 'chake/backend/local'

describe Chake::Backend::Local do

  let(:node) { Chake::Node.new('local://myhost/srv/chef') }
  let(:backend) { Chake::Backend::Local.new(node) }

  it('rsyncs') { expect(backend.rsync_dest).to eq('/srv/chef/') }
  it('runs commands') do
    io = StringIO.new("line 1\nline 2\n")
    IO.should_receive(:popen).with(['sh', '-c', 'something']).and_return(io)
    backend.should_receive(:puts).with("myhost: line 1")
    backend.should_receive(:puts).with("myhost: line 2")
    backend.run('something')
  end

end
