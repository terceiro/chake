require 'spec_helper'

describe Chake::Backend::Local do

  include_examples "Chake::Backend", Chake::Backend::Local

  let(:node) { Chake::Node.new('local://myhost/srv/chef') }

  it('runs commands with sh -c') { expect(backend.command_runner).to eq(['sh', '-c']) }

  it('rsyncs locally') { expect(backend.rsync_dest).to eq('/srv/chef/') }

  it('skips if hostname is not the local hostname') do
    Socket.stub(:gethostname).and_return('otherhost')
    expect(node.skip?).to eq(true)
  end
end
