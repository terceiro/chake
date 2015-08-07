namespace :bundler do
  require "bundler/gem_tasks"
end

task :test do
  sh 'rspec', '--color'
end

pkg = Gem::Specification.load('chake.gemspec')

task 'build:tarball' => [:build] do
  chdir 'pkg' do
    sh 'gem2tgz', "#{pkg.name}-#{pkg.version}.gem"
  end
end

desc 'Create Debian source package'
task 'build:debsrc' => ['build:tarball'] do
  dirname = "#{pkg.name}-#{pkg.version}"
  chdir 'pkg' do
    sh 'gem2deb', '--no-wnpp-check', '-s', '-p', pkg.name, "#{dirname}.tar.gz"
    chdir dirname do
      sh 'dpkg-buildpackage', '-S', '-us', '-uc'
    end
  end
end

desc 'Builds and installs Debian package'
task 'deb:install' => 'build:debsrc'do
  chdir "pkg/#{pkg.name}-#{pkg.version}" do
    sh 'fakeroot debian/rules binary'
  end
  sh 'sudo', 'dpkg', '-i', "pkg/#{pkg.name}_#{pkg.version}-1_all.deb"
end

desc 'Create source RPM package'
task 'build:rpmsrc' => ['build:tarball', 'pkg/chake.spec']

file 'pkg/chake.spec' => ['chake.spec.erb', 'lib/chake/version.rb'] do |t|
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

task :check_tag do
  last_tag = `git tag | sort -V`.split.last
  if last_tag == "v#{pkg.version}"
    fail "Version #{pkg.version} was already released!"
  end
end

desc 'checks if the latest release is properly documented in ChangeLog.md'
task :check_changelog do
  begin
    sh 'grep', '^#\s*' + pkg.version.to_s, 'ChangeLog.md'
  rescue
    puts "Version #{pkg.version} not documented in ChangeLog.md!"
    raise
  end
end

task :release => [:check_tag, :check_changelog, :test, 'bundler:release', :obs]

task :default => :test
