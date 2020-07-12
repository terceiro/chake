require 'chake/node'

module Chake
  class << self
    attr_accessor :nodes
  end
end

nodes_file = ENV['CHAKE_NODES'] || 'nodes.yaml'
nodes_directory = ENV['CHAKE_NODES_D'] || 'nodes.d'
node_data = File.exist?(nodes_file) && YAML.load_file(nodes_file) || {}
Dir.glob(File.join(nodes_directory, '*.yaml')).sort.each do |f|
  node_data.merge!(YAML.load_file(f))
end

Chake.nodes = node_data.map { |node, data| Chake::Node.new(node, data) }.reject(&:skip?).uniq(&:hostname)
