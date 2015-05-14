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
