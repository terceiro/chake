require 'chake/node'
require 'chake/config_manager/chef'

describe Chake::ConfigManager::Chef do
  let(:node) do
    Chake::Node.new('foobar')
  end

  subject do
    Chake::ConfigManager::Chef.new(node)
  end

  it 'provides a name' do
    expect(subject.name).to eq('chef')
  end

  it 'calls chef-solo on converge' do
    expect(subject).to receive(:logging).and_return('-l debug')
    expect(node).to receive(:run_as_root).with(%r{chef-solo -c #{node.path}/config.rb -l debug -j #{node.path}/#{Chake.tmpdir}/foobar.json})
    subject.converge
  end

  it 'calls chef-solo on apply' do
    expect(subject).to receive(:logging).and_return('-l debug')
    expect(node).to receive(:run_as_root).with(%r{chef-solo -c #{node.path}/config.rb -l debug -j #{node.path}/#{Chake.tmpdir}/foobar.json --override-runlist recipe\[myrecipe\]})
    subject.apply('myrecipe')
  end

  context 'logging' do
    it 'logs when requested' do
      expect(subject.send(:logging)).to eq('')
    end
    it 'only show fatal errrrs when requested' do
      node.silent = true
      expect(subject.send(:logging)).to eq('-l fatal')
    end
  end
end
