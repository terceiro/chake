require "bundler/gem_tasks"

task :test do
  sh 'rspec', '--color'
end

pkg = Gem::Specification.load('chake.gemspec')

task :build do
  chdir 'pkg' do
    sh 'gem2tgz', "#{pkg.name}-#{pkg.version}.gem"
  end
end

desc 'Create Debian source package'
task 'build:debsrc' => [:build] do
  dirname = "#{pkg.name}-#{pkg.version}"
  chdir 'pkg' do
    sh 'gem2deb', '--no-wnpp-check', '-s', '-p', pkg.name, "#{dirname}.gem"
    chdir dirname do
      sh 'dpkg-buildpackage', '-S', '-us', '-uc'
    end
  end
end

desc 'Create source RPM package'
task 'build:rpmsrc' => [:build, 'pkg/chake.spec']

file 'pkg/chake.spec' => 'chake.spec.erb' do |t|
  require 'erb'
  pkg = Gem::Specification.load('chake.gemspec')
  template =  ERB.new(File.read('chake.spec.erb'))
  File.open(t.name, 'w') do |f|
    f.puts(template.result(binding))
  end
  puts "Generated #{t.name}"
end

task 'build:all' => ['build:debsrc', 'build:rpmsrc']

task :obs => 'build:all' do
  if !File.exist?('tmp/obs/home:terceiro:chake/chake')
    mkdir_p 'tmp/obs'
    chdir 'tmp/obs' do
      sh 'osc', 'checkout', 'home:terceiro:chake', 'chake'
    end
  end

  # remove old files
  chdir 'tmp/obs/home:terceiro:chake/chake' do
    Dir.glob('*').each do |f|
      sh 'osc', 'remove', '--force', f
    end
  end

  # copy over new files
  [
    "pkg/#{pkg.name}-#{pkg.version}.tar.gz",
    "pkg/#{pkg.name}.spec",
    "pkg/#{pkg.name}_#{pkg.version}.orig.tar.gz",
    "pkg/#{pkg.name}_#{pkg.version}-1.debian.tar.xz",
    "pkg/#{pkg.name}_#{pkg.version}-1.dsc",
  ].each do |f|
    sh 'cp', '--dereference', f, 'tmp/obs/home:terceiro:chake/chake'
  end

  # push new files to the repository
  chdir 'tmp/obs/home:terceiro:chake/chake' do
    Dir.glob('*').each do |f|
      sh 'osc', 'add', f
    end
    sh 'osc', 'commit', '--message', "#{pkg.name}, version #{pkg.version}"
  end

end

desc 'lists changes since last release'
task :changelog do
  last_tag = `git tag | sort -V`.split.last
  sh 'git', 'shortlog', last_tag + '..'
end

task :release => [:test, :obs]

task :default => :test
