require 'chake/node'

module Chake
  class << self
    attr_accessor :nodes
  end
end

nodes_file = ENV['CHAKE_NODES'] || 'nodes.yaml'
nodes_directory = ENV['CHAKE_NODES_D'] || 'nodes.d'
nodes = File.exist?(nodes_file) && YAML.load_file(nodes_file) || {}
nodes.values.each do |node|
  node['chake_metadata'] = { 'definition_file' => nodes_file }
end
Dir.glob(File.join(nodes_directory, '*.yaml')).sort.each do |f|
  file_nodes = YAML.load_file(f)
  file_nodes.values.each do |node|
    node['chake_metadata'] = { 'definition_file' => f }
  end
  nodes.merge!(file_nodes)
end

Chake.nodes = nodes.map { |node, data| Chake::Node.new(node, data) }.reject(&:skip?).uniq(&:hostname)
