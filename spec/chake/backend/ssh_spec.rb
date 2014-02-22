require 'spec_helper'

describe Chake::Backend::Ssh do

  include_examples "Chake::Backend", Chake::Backend::Ssh, ->() {  }

  let(:node) { Chake::Node.new('ssh://myuser@myhost/srv/chef') }

  it('runs commands with ssh') { expect(backend.command_runner).to eq(['ssh', 'myuser@myhost']) }

  it('rsyncs over ssh') { expect(backend.rsync_dest).to eq('myuser@myhost:/srv/chef/') }

end
