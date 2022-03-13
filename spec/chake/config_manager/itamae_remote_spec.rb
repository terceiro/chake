require 'spec_helper'
require 'chake/node'
require 'chake/config_manager/itamae_remote'

describe Chake::ConfigManager::ItamaeRemote do
  let(:node) do
    Chake::Node.new('somehost').tap do |n|
      n.silent = true
      n.data['itamae-remote'] = ['foo.rb', 'bar.rb']
    end
  end
  let(:cfg) { Chake::ConfigManager.get(node) }

  it 'is detected correctly' do
    expect(cfg).to be_a(Chake::ConfigManager::ItamaeRemote)
  end

  it 'requires uploading' do
    expect(cfg.needs_upload?).to eq(true)
  end

  it 'calls itamae remotely to converge' do
    expect(node).to receive(:run_as_root).with(
      a_string_matching(%r{itamae.*#{node.path}/foo.rb.*#{node.path}/bar.rb})
    )
    cfg.converge
  end

  it 'calls itamae remotely to apply' do
    expect(node).to receive(:run_as_root).with(
      a_string_matching(%r{itamae.*#{node.path}/doit.rb})
    )
    cfg.apply('doit.rb')
  end

  it 'handles silent mode' do
    node.silent = true
    expect(node).to receive(:run_as_root).with(
      a_string_matching(/--log-level\\=warn/)
    )
    cfg.converge
  end

  it 'has a name with dashes' do
    expect(cfg.name).to eq('itamae-remote')
  end
end
