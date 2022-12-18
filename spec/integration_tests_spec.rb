require 'fileutils'
require 'pathname'
require 'tmpdir'

describe 'Chake' do
  include FileUtils

  def sh(*args)
    cmd = Shellwords.join(args)
    lib = [Pathname.new(__FILE__).parent.parent / 'lib', ENV['RUBYLIB']].compact.join(':')
    path = [Pathname.new(__FILE__).parent.parent / 'bin', ENV['PATH']].join(':')
    env = {
      'RUBYLIB' => lib,
      'PATH' => path
    }
    unless system(env, *args, out: ['.out', 'w'], err: ['.err', 'w'])
      out = File.read('.out')
      err = File.read('.err')
      raise "Command [#{cmd}] failed with exit status #{$CHILD_STATUS} (PATH = #{path}, RUBYLIB = #{lib}).\nstdout:\n#{out}\nstderr:\n#{err}"
    end
    rm_f '.log'
  end

  def chake(*args)
    cmd = [Gem.ruby, '-S', 'chake'] + args
    sh(*cmd)
  end

  def rake(*args)
    cmd = [Gem.ruby, '-S', 'rake'] + args
    sh(*cmd)
  end

  def project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  it 'loads node information' do
    project do
      chake 'init'
      rake 'nodes'
    end
  end
end
