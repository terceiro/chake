require 'chake/node'

describe Chake::Node do

  before do
    ent = double
    allow(ent).to receive(:name).and_return('jonhdoe')
    allow(Etc).to receive(:getpwuid).and_return(ent)
  end

  let(:simple) { Chake::Node.new('hostname') }
  it('has a name') { expect(simple.hostname).to eq('hostname') }
  it('uses ssh by default') { expect(simple.connection).to be_an_instance_of(Chake::Connection::Ssh) }
  it('user current username by default') {
    expect(simple.username).to eq('jonhdoe')
  }
  it('writes to specified path') {
    node = Chake::Node.new("ssh://host.tld/path/to/config")
    expect(node.path).to eq("/path/to/config")
  }

  let(:with_username) { Chake::Node.new('username@hostname') }
  it('accepts username') { expect(with_username.username).to eq('username') }
  it('uses ssh') { expect(with_username.connection).to be_an_instance_of(Chake::Connection::Ssh) }

  let(:with_connection) { Chake::Node.new('local://hostname')}
  it('accepts connection as URI scheme') { expect(with_connection.connection).to be_an_instance_of(Chake::Connection::Local) }

  it('wont accept any connection') do
    expect { Chake::Node.new('foobar://bazqux').connection }.to raise_error(ArgumentError)
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
    expect(with_port_but_no_scheme.connection.to_s).to eq('ssh')
  end

  [:run, :run_as_root, :rsync_dest].each do |method|
    it("delegates #{method} to connection") do
      node = simple

      connection = double
      args = Object.new
      allow(node).to receive(:connection).and_return(connection)

      expect(connection).to receive(method).with(args)
      node.send(method, args)
    end
  end

  it "delegates converge to config_manager" do
    node = simple
    expect(node.config_manager).to receive(:converge)
    node.converge
  end

  it "delegates apply to config_manager" do
    node = simple
    expect(node.config_manager).to receive(:apply).with("myrecipe")
    node.apply("myrecipe")
  end

  it 'falls back to writing to path specified by config manager' do
    expect(simple.path).to eq(simple.config_manager.path)
  end


end
