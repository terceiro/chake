require 'chake/node'
require 'chake/config_manager'
require 'chake/config_manager/shell'

describe Chake::ConfigManager::Shell do |_c|
  let(:node) do
    Chake::Node.new('foobar').tap do |n|
      allow(n).to receive(:path).and_return(nil)
    end
  end
  it 'accepts node with explicit config_manager in data' do
    node.data['config_manager'] = 'shell'
    expect(Chake::ConfigManager.get(node)).to be_a(Chake::ConfigManager::Shell)
  end
  it 'accepts node with `shell` in data' do
    node.data['shell'] = ['date']
    expect(Chake::ConfigManager.get(node)).to be_a(Chake::ConfigManager::Shell)
  end

  let(:subject) { Chake::ConfigManager::Shell.new(node) }

  it 'calls all shell commands on converge' do
    node.data['shell'] = %w[date true]
    expect(node).to receive(:run_as_root).with("sh -xec 'date && true'")
    subject.converge
  end

  it 'changes to node path to run commands' do
    node.data['shell'] = %w[true]
    allow(node).to receive(:path).and_return('/foo')
    expect(node).to receive(:run_as_root).with("sh -xec 'cd /foo && true'")
    subject.converge
  end

  it 'calls given shell command on apply' do
    node.data['shell'] = %w[date true]
    expect(node).to receive(:run_as_root).with("sh -xec 'reboot'")
    subject.apply('reboot')
  end

  it 'hides output on converge in silent mode' do
    node.data['shell'] = ['date']
    node.silent = true
    expect(node).to receive(:run_as_root).with("sh -ec 'date' >/dev/null")
    subject.converge
  end

  it 'hides output on apply in silent mode' do
    node.data['shell'] = ['date']
    node.silent = true
    expect(node).to receive(:run_as_root).with("sh -ec 'reboot' >/dev/null")
    subject.apply('reboot')
  end
end
