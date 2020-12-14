chake(1) -- serverless configuration management tool
========================================

## SYNOPSIS

`chake` init

`chake` [rake arguments]

## Description

chake is a tool that helps you manage multiple hosts without the need for a
central server. Configuration is managed in a local directory, which should
(but doesn't need to ) be under version control with **git(1)** or any other
version control system.

Configuration is deployed to managed hosts remotely, either by invoking a
configuration management tool that will connect to them, or by first uploading
the necessary configuration and them remotely running a tool on the hosts.

## Supported configuration managers.

chake supports the following configuration management tools:

* **itamae**: configuration is applied by running the itamae command line tool
  on the management host; no configuration needs to be uploaded to the managed
  hosts. See chake-itamae(7) for details.
* **shell**: the local repository is copied to the host, and the shell commands
  specified in the node configuration is executed from the directory where that
  copy is. See chake-shell(7) for details.
* **chef**: the local repository is copied to the host, and **chef-solo** is
  executed remotely on the managed host. See chake-chef(7) for details.

Beyond applying configuration management recipes on the hosts, chake also
provides useful tools to manage multiple hosts, such as listing nodes, running
commands against all of them simultaneously, logging in to interactive
shells, and others.

## creating the repository

    $ chake init[:configmanager]

This will create an initial directory structure. Some of the files are specific
to your your chosen **configmanager**, which can be one of [SUPPORTED
CONFIGURATION MANAGERS]. The following files, though, will be common to any
usage of chake:

* `nodes.yaml`: where you will list the hosts you will be managing, and what
  recipes to apply to each of them.
* `nodes.d`: a directory with multiple files in the same format as nodes.yaml.
  All files matching `*.yaml` in it will be added to the list of nodes.
* `Rakefile`: Contains just the `require 'chake'` line. You can augment it with
  other tasks specific to your intrastructure.

If you omit _configmanager_, `itamae` will be used by default.

After the repository is created, you can call either `chake` or `rake`, as they
are completely equivalent.

## Managing nodes

Just after you created your repository, the contents of `nodes.yaml` is the
following:

```yaml
host1.mycompany.com:
  itamae:
    - roles/basic.rb
```

The exact contents depends on the chosen configuration management tool.

You can list your hosts with `rake nodes`:

```
$ rake nodes
host1.mycompany.com                      ssh
```

To add more nodes, just append to `nodes.yaml`:

```yaml
host1.mycompany.com:
  itamae:
    - roles/basic.rb
host2.mycompany.com:
  itamae:
    - roles/basic.rb
```

And chake now knows about your new node:

```
$ rake nodes
host1.mycompany.com                      ssh
host2.mycompany.com                      ssh
```

## Preparings nodes to be managed

Nodes have very few initial requirements to be managed with `chake`:

- The node must be accessible via SSH.
- The user you connect to the node must either be `root`, or be allowed to run
  `sudo` (in which case `sudo` must be installed).

**A note on password prompts:** every time chake calls ssh on a node, you may
be required to type in your password; every time chake calls sudo on the node,
you may be require to type in your password. For managing one or two nodes this
is probably fine, but for larger numbers of nodes it is not practical. To avoid
password prompts, you can:

- Configure SSH key-based authentication. This is more secure than using passwords.
  While you are at it, you also probably want disable password authentication
  completely, and only allow key-based authentication
- Configure passwordless `sudo` access for the user you use to connect to your
  nodes.

## Checking connectivity and initial host setup

To check whether hosts are correctly configured, you can use the `check` task:

```
$ rake check
```

That will run the the `sudo true` command on each host. If that pass without
you having to type any passwords, it means that:

* you have SSH access to each host; and
* the user you are connecting as has password-less sudo correctly setup.

## Applying configuration

Note that by default all tasks that apply to all hosts will run in parallel,
using rake's support for multitasks. If for some reason you need to prevent
that, you can pass `-j1` (or --jobs=1`) in the rake invocation. Note that by
default rake will only run N+4 tasks in parallel, where N is the number of
cores on the machine you are running it. If you have more than N+4 hosts and
want all of them to be handled in parallel, you might want to pass `-j` (or
`--jobs`), without any number, as the last argument; with that rake will have
no limit on the number of tasks to perform in parallel.

To apply the configuration to all nodes, run

```
$ rake converge
```

To apply the configuration to a single node, run

```
$ rake converge:$NODE
```

To apply a single recipe on all nodes, run

```
$ rake apply[myrecipe]
```

What `recipe` is depends on the configuration manager.


To apply a single recipe on a specific node, run

```
$ rake apply:$NODE[myrecipe]
```

If you don't inform a recipe in the command line, you will be prompted for one.

To run a shell command on all nodes, run

```
$ rake run
```
The above will prompt you for a command, then execute it on all nodes.

To pass the command to run in the command line, use the following syntax:

```
$ rake run[command]
```

If the `command` you want to run contains spaces, or other characters that are
special do the shell, you have to quote them, for example:

```
$ rake run["cat /etc/hostname"]
```


To run a shell command on a specific node, run

```
$ rake run:$NODE[command]
```

As before, if you run just `rake run:$NODE`, you will be prompted for the
command.

To list all existing tasks, run:

```
$ rake -T
```

## Writing configuration management code

As chake supports different configuration management tools, the specifics of
configuration management code depends on the the tool you choose. See the
corresponding documentation.

## The node bootstrapping process

Some of the configuration management tools require some software to be
installed on the managed hosts. When that's the case, chake acts on a node for
the first time, it has to bootstrap it. The bootstrapping process includes
doing the following:

- installing and configuring the needed software
- setting up the hostname

## Node URLs

The keys in the hash that is represented in `nodes.yaml` is a node URL. All
components of the URL but the hostname are optional, so just listing hostnames
is the simplest form of specifying your nodes. Here are all the components of
the node URLs:

```
[connection://][username@]hostname[:port][/path]
```

* `connection`: what to use to connect to the host. `ssh` or `local` (default: `ssh`)
* `username`: user name to connect with (default: the username on your local workstation)
* `hostname`: the hostname to connect to (default: _none_)
* `port`: port number to connect to (default: 22)
* `/path`:  where to store the cookbooks at the node (default: `/var/tmp/chef.$USERNAME`)

## Extra features

### Hooks

You can define rake tasks that will be executed before bootstrapping nodes,
before uploading configuration management content to nodes, and before
converging. To do this, you just need to enhance the corresponding tasks:

* `bootstrap_common`: executed before bootstrapping nodes (even if nodes have
  already been bootstrapped)
* `upload_common`: executed before uploading content to the node
* `converge_common`: executed before converging (i.e. running chef)
* `connect_common`: executed before doing any action that connects to any of
  the hosts. This can be used for example to generate a ssh configuration file
  based on the contents of the nodes definition files.

Example:

```ruby
task :bootstrap_common do
  sh './scripts/pre-bootstrap-checks'
end
```

### Encrypted files

Any files ending matching `*.gpg` and `*.asc` will be decrypted with GnuPG
before being sent to the node (for the configuration management tools that
required files to be sent). You can use them to store passwords and other
sensitive information (SSL keys, etc) in the repository together with the rest
of the configuration.

For configuration managers that don't require uploading files to the managed
node, this decryption will happen right before converging or applying single
recipes, and the decrypted files will be wiped right after that.

If you use this feature, make sure that you have the `wipe` program installed.
This way chake will be able to delete the decrypted files in a slightly more
secure way, after being done with them.

### repository-local SSH configuration

If you need special SSH configuration parameters, you can create a file called
`.ssh_config` (or whatever file name you have in the `$CHAKE_SSH_CONFIG`
environment variable, see below for details) in at the root of your repository,
and chake will use it when calling `ssh`.

### Logging in to a host

To easily login to one of your host, just run `rake login:$HOSTNAME`. This will
automatically use the repository-local SSH configuration as above so you don't
have to type `-F .ssh_config` all the time.

### Running all SSH invocations with some prefix command

Some times, you will also want or need to prefix your SSH invocations with some
prefix command in order to e.g. tunnel it through some central exit node. You
can do this by setting `$CHAKE_SSH_PREFIX` on your environment. Example:

```bash
CHAKE_SSH_PREFIX=tsocks rake converge
```

The above will make all SSH invocations to all hosts be called as `tsocks ssh
[...]`

### Converging local host

If you want to manage your local workstation with chake, you can declare a
local node using the "local" connection type, like this (in `nodes.yaml`):

```yaml
local://thunderbolt:
  itamae:
    - role/workstation.rb
```

To apply the configuration to the local host, you can use the conventional
`rake converge:thunderbolt`, or the special target `rake local`.

When converging all nodes, `chake` will skip nodes that are declared with the
`local://` connection and whose hostname does not match the hostname  in the
declaration. For example:

```yaml
local://desktop:
  itamae:
    - role/workstation.rb
local://laptop:
  itamae:
    - role/workstation.rb
```

When you run `rake converge` on `desktop`, `laptop` will be skipped, and
vice-versa.

### Accessing node data from your own tasks

It's often useful to be able to run arbitrary commands against the data you
have about nodes. You can use the `Chake.nodes` for that. For example, if you
want to geolocate each of yours hosts:

```ruby
task :geolocate do
  Chake.nodes.each do |node|
    puts "#{node.hostname}: %s" % `geoiplookup #{node.hostname}`.strip
  end
end
```

## Environment variables

* `$CHAKE_SSH_CONFIG`:
  Local SSH configuration file. Defaults to `.ssh_config`.
* `$CHAKE_SSH_PREFIX`:
  Command to prefix SSH (and rsync over SSH) calls with.
* `$CHAKE_RSYNC_OPTIONS`:
  extra options to pass to `rsync`. Useful to e.g. exclude large files from
  being upload to each server.
* `$CHAKE_NODES`:
  File containing the list of servers to be managed. Default: `nodes.yaml`.
* `$CHAKE_NODES_D`:
  Directory containing node definition files servers to be managed. Default: `nodes.d`.
* `$CHAKE_TMPDIR`:
  Directory used to store temporary cache files. Default: `tmp/chake`.
* `$CHAKE_CHEF_CONFIG`:
  Chef configuration file, relative to the root of the repository. Default: `config.rb`.

## See also

* **rake(1)**
* **chake-itamae(7)**, https://itamae.kitchen/
* **chake-shell(7)**
* **chake-chef(7)**, **chef-solo(1)**, https://docs.chef.io/
