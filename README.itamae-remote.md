chake-itamae-remote(7) -- configure chake nodes with a remote itamae
====================================================================

## Description

This configuration manager will run **itamae(1)** on each remote node. This is
different from the _itamae_ configuration manager, which runs itamae on your
workstation (the host running chake). _itamae-remote_ will run itamae
individually on each node, which is one order of magnitude faster. This
requires itamae to be installed on each node, and that will be taken care of
automatically by the bootstrapping process.

## Configuration

The _itamae-remote_ configuration manager requires one key called
`itamae-remote`, and the value must be a list of strings representing the list
of recipes to apply to the node when converging.

```yaml
host1.mycompany.com:
  itamae-remote:
    - cookbooks/basic/default.rb
    - roles/server.rb
  service1:
    option1: "here we go"
```

Any extra configuration under `host1.mycompany.com` will be saved to a JSON file
and given to the itamae --node-json option in the command line. For example,
the above configuration will produce a JSON file that looks like this:

```json
{
  "itamae": [
    "cookbooks/basic.rb",
    "roles/server.rb"
  ]
  ,
  "service1": {
    "option1": "here we go"
  }
}
```

Inside itamae recipes, you can access those values by using the `node` object.
For example:

```ruby
template "/etc/service1.conf.d/option1.conf" do
  variables option1: node["option1"]
end
```

## Bootstrapping

The bootstrapping process will make sure itamae is installed. The node hostname
will be set according to your chake configuration.

## See also

* **chake(1)**
