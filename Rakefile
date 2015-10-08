namespace :bundler do
  require "bundler/gem_tasks"
end

task :test do
  sh 'rspec', '--color'
end

pkg = Gem::Specification.load('chake.gemspec')

task 'build:tarball' => 'bundler:build' do
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

desc 'Makes a release'
task :release => [:check_tag, :check_changelog, :test, 'bundler:release']

task :default => :test
