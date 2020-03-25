require 'pathname'
require 'chake/node'
require 'chake/config_manager'

describe Chake::ConfigManager do
  subject { Chake::ConfigManager.new(Chake::Node.new('ssh://user@hostname.tld')) }
  it 'provides a path' do
    allow(subject).to receive(:name).and_return('xyz')
    expect(subject.path).to eq('/var/tmp/xyz.user')
  end

  it 'provides bootstrap scripts' do
    bootstrap_steps = subject.bootstrap_steps
    expect(bootstrap_steps).to_not be_empty
    bootstrap_steps.each do |path|
      expect(Pathname(path)).to exist
    end
  end
end
