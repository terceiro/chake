require 'chake/node'

describe Chake::Node do

  before do
    ent = double
    ent.stub(:name).and_return('jonhdoe')
    Etc.stub(:getpwuid).and_return(ent)
  end

  let(:simple) { Chake::Node.new('hostname') }
  it('has a name') { expect(simple.hostname).to eq('hostname') }
  it('uses ssh by default') { expect(simple.backend).to be_an_instance_of(Chake::Backend::Ssh) }
  it('user current username by default') {
    expect(simple.username).to eq('jonhdoe')
  }
  it('writes to /var/tmp/chef.$username') {
    expect(simple.path).to eq('/var/tmp/chef.jonhdoe')
  }

  let(:with_username) { Chake::Node.new('username@hostname') }
  it('accepts username') { expect(with_username.username).to eq('username') }
  it('uses ssh') { expect(with_username.backend).to be_an_instance_of(Chake::Backend::Ssh) }

  let(:with_backend) { Chake::Node.new('local://hostname')}
  it('accepts backend as URI scheme') { expect(with_backend.backend).to be_an_instance_of(Chake::Backend::Local) }

  it('wont accept any backend') do
    expect { Chake::Node.new('foobar://bazqux').backend }.to raise_error(ArgumentError)
  end

  let(:with_data) { Chake::Node.new('local://localhost', 'run_list' => ['recipe[common]']) }
  it('takes data') do
    expect(with_data.data).to be_a(Hash)
  end

  [:run, :run_as_root, :rsync_dest].each do |method|
    it("delegates #{method} to backend") do
      node = simple

      backend = double
      args = Object.new
      node.stub(:backend).and_return(backend)

      backend.should_receive(method).with(args)
      node.send(method, args)
    end
  end

end
