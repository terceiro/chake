# 0.12

* Switch manpage build from ronn to asciidoctor
* Add ability to override the Chef configuration file by setting
  `$CHAKE_CHEF_CONFIG` (default: `config.rb`)
* bootstrap: ensure short hostname is in /etc/hosts

# 0.11

* bootstrap: make sure FQDN matches hostname
* Add `rake check` task to check SSH connectivity and sudo setup
* Add tasks to apply a single recipe to nodes: `rake apply[recipe]` and `rake
  apply:$NODE[recipe]`. If `[recipe]` is not passed in the command line, the
  user is prompted for the recipe name.
* run task changed to have the same interface and behavior as the new apply
  task: `rake run[command]`, or `rake run:$NODE[command]`. If `[command]` is
  not passed in the command line, the user is prompted for the command.

# 0.10.2

* Fix check for modified files at the upload phase. Now chake will properly
  avoiding rsync calls when there is no changed files since the latest upload.
* Fix generated RPM spec file. Will now properly build, install, and work under
  both CentOS 7 and Fedora 22+.
* Collect test coverage statistics when running tests.
  * Added dependency on simplecov

# 0.10.1

* actually implement support for custom ports in Node URL's. Despite being
  documented, that didn't actually work until now.

# 0.10

* Add hook functionality. See README/manpage for documentation.
* README.md: a few reviews

# 0.9.1

* fix manpage installation path

# 0.9

* fix build step for obs uploads
* add infrastructure to build and install a manpage
* Add support for a nodes.d/ directory; very useful when dealing with a larger
  amount of nodes.

# 0.8

* gemspec: minor improvements in the long description
* LICENSE.txt: fixed license name
* run: print small message before prompting
* Add history support for the `run` tasks
* Abort `run` tasks if no command is provided

# 0.7

* gemspec: improve summary and description
* Also for encrypted files under $cookbook/files/, and not only under
  $cookbook/files/\*/.
* Allow overriding tmpdir with `$CHAKE_TMPDIR`
* Stop cloud-init from resetting the hostname

# 0.6

* Support a ssh prefix command by setting `$CHAKE_SSH_PREFIX` in the
  environment. For example, `CHAKE_SSH_PREFIX=tsocks` will make all ssh
  invocations as `tocks ssh ...` instead of just `ssh ...`.

# 0.5

* Add a task login:$host that you can use to easily log in to any of your
  hosts.

# 0.4.3

* When running remote commands as root, run `sudo COMMAND` directly instead of
  `sudo sh -c "COMMAND"`. Under over-restrictive sudo setups (i.e. one in which
  you cannot run a shell as root), `sudo sh -c "FOO"` will not be allowed.

# 0.4.2

* tmp/chake: create only when actually needed
* Control nodes files with `$CHAKE_NODES`

# 0.4.1

* Don't always assume the local username as the remote username for SSH
  connections:
  * `user@host`: connect with `user@host`
  * `host`: connect with `host` (username will be obtained by SSH itself from
    either its configuration files or the current username)

# 0.4.0

* Redesign build of RPM package
* Output of command run on nodes is now aligned
* Change storage of temporary files from .tmp to tmp/chake
* The JSON node attributes files generated in tmp/chake are not readable
* SSH config file can now be controlled with the `$CHAKE_SSH_CONFIG`
  environment variable
* Extra options for rsync can now be passed in the `$CHAKE_RSYNC_OPTIONS`
  environment variable
* Chake::VERSION is now available in Rakefiles
* update test suite to use new rspec syntax instead the old one which is
  obsolete in rspec 3.
  * Thanks to Athos Ribeiro.

# 0.3.3

* rsync: exclude cache/ to work with the version of rsync in OSX

# 0.3.2

* Now finally, hopefully, really fix RPM builds
* chake init: rename 'myhost' → 'basics'
* The official home is on gitlab
* Completed basic documentation

# 0.3.1

* Fix setting hostname when bootstrapping
* Rakefile: do not allow releases without a changelog entry
* Now *really* fix RPM builds, hopefully

# 0.3

* Fix RPM build
* bootstrap: set hostname

# 0.2.3

* No functional changes
* Small changes to make chake compatible with Debian 7, and most of the
  RPM-based distributions
