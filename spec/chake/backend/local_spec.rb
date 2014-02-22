require 'spec_helper'

describe Chake::Backend::Local do

  include_examples "Chake::Backend", Chake::Backend::Local

  let(:node) { Chake::Node.new('local://myhost/srv/chef') }

  it('runs commands with sh -c') { expect(backend.command_runner).to eq(['sh', '-c']) }

  it('rsyncs locally') { expect(backend.rsync_dest).to eq('/srv/chef/') }
end
