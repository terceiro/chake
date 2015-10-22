require 'chake/node'

describe Chake::Node do

  before do
    ent = double
    allow(ent).to receive(:name).and_return('jonhdoe')
    allow(Etc).to receive(:getpwuid).and_return(ent)
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

  let(:with_port) { Chake::Node.new('ssh://foo.bar.com:2222') }
  it('accepts a port specification') do
    expect(with_port.port).to eq(2222)
  end

  let(:with_port_but_no_scheme) { Chake::Node.new('foo.bar.com:2222') }
  it('accepts a port specification without a scheme') do
    expect(with_port_but_no_scheme.port).to eq(2222)
    expect(with_port_but_no_scheme.backend.to_s).to eq('ssh')
  end

  [:run, :run_as_root, :rsync_dest].each do |method|
    it("delegates #{method} to backend") do
      node = simple

      backend = double
      args = Object.new
      allow(node).to receive(:backend).and_return(backend)

      expect(backend).to receive(method).with(args)
      node.send(method, args)
    end
  end

end
