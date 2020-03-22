require 'spec_helper'

describe Chake::Connection::Local do

  include_examples "Chake::Connection", Chake::Connection::Local

  let(:node) { Chake::Node.new('local://myusername@myhost/srv/chef') }

  it('runs commands with sh -c') { expect(connection.command_runner).to eq(['sh', '-c']) }

  it('rsyncs locally') { expect(connection.rsync_dest).to eq('/srv/chef/') }

  it('skips if hostname is not the local hostname') do
    allow(Socket).to receive(:gethostname).and_return('otherhost')
    expect(node.skip?).to eq(true)
  end
end
