chake-shell(7) -- configure chake nodes with shell
==================================================

## Description

This configuration manager is a simpler wrapper for running a list of shell
commands on the nodes.

## Configuration

The _shell_ configuration manager requires one key called `shell`, and the
value must be a list of strings representing the list of commands to run on the
node when converging.

```yaml
host1.mycompany.com:
  shell:
    - echo "HELLO WORLD"
```

## Bootstrapping

Very little bootstrapping is required for this configuration manager, as we
hope every node you could possibly want to manage with it already has a POSIX
shell as `/bin/sh`. During bootstrapping, only the node hostname will be set
according to your chake configuration.

## See also

* **chake(1)**
