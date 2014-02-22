require 'chake/backend/ssh'

describe Chake::Backend::Ssh do

  let(:node) { Chake::Node.new('ssh://myuser@myhost/srv/chef') }
  let(:backend) { Chake::Backend::Ssh.new(node) }

  it('rsyncs') { expect(backend.rsync_dest).to eq("myuser@myhost:/srv/chef/") }
  it('runs commands') do
    io = StringIO.new("line 1\nline 2\n")
    IO.should_receive(:popen).with(['ssh', 'myuser@myhost', 'something']).and_return(io)
    backend.should_receive(:puts).with("myhost: line 1").once
    backend.should_receive(:puts).with("myhost: line 2").once

    backend.run('something')
  end

end
