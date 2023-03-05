require 'spec_helper'
require 'chake/node'
require 'chake/config_manager/itamae'

describe Chake::ConfigManager::Itamae do
  let(:hostname) { 'foobar' }
  let(:node) do
    Chake::Node.new(hostname).tap do |n|
      n.silent = true
      n.data['itamae'] = ['foo.rb', 'bar.rb']
    end
  end
  let(:cfg) { Chake::ConfigManager::Itamae.new(node) }
  let(:output) { StringIO.new("line1\nline2\n") }

  it 'does not require uploading' do
    expect(cfg.needs_upload?).to eq(false)
  end

  it 'calls itamae when converging' do
    expect(IO).to receive(:popen).with(
      array_including('itamae', 'foo.rb', 'bar.rb'),
      'r',
      err: %i[child out]
    ).and_return(output)
    cfg.converge
  end

  it 'calls itamae when applying' do
    expect(IO).to receive(:popen).with(
      array_including('itamae', 'foobarbaz.rb'),
      'r',
      err: %i[child out]
    ).and_return(output)
    cfg.apply('foobarbaz.rb')
  end

  context 'for ssh hosts' do
    let(:hostname) { 'ssh://theusernanme@thehostname' }
    it 'calls itamae ssh subcommand' do
      expect(IO).to receive(:popen).with(
        array_including('itamae', 'ssh', '--host=thehostname', '--user=theusernanme'),
        anything,
        err: anything
      ).and_return(output)
      cfg.converge
    end
  end

  context 'for local hosts' do
    let(:hostname) { 'local://localhostname' }
    it 'calls itamae with local subcommand' do
      expect(IO).to receive(:popen).with(
        array_including('itamae', 'local', /--node-json=.*/, 'foo.rb', 'bar.rb'),
        anything,
        err: anything
      ).and_return(output)
      cfg.converge
    end
  end

  it 'throws an error for unsupported connection' do
    allow(node).to receive(:connection).and_return(Object.new)
    expect { cfg.converge }.to raise_error(NotImplementedError)
  end

  it 'handles silent mode' do
    expect(IO).to receive(:popen).with(
      array_including('--log-level=warn'),
      anything,
      err: anything
    ).and_return(output)
    cfg.converge
  end

  RSpec::Matchers.define_negated_matcher :array_excluding, :include

  it 'handles non-silent mode' do
    node.silent = false
    expect(IO).to receive(:popen).with(
      array_excluding('--log-level=warn'),
      anything,
      err: anything
    ).and_return(output)
    silence($stdout) { cfg.converge }
  end
end
