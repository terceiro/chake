chake-itamae(7) -- configure chake nodes with itamae
====================================================

## Description

This configuration manager will run **itamae(1)** against your nodes.

## Configuration

The _itamae_ configuration manager requires one key called `itamae`, and the
value must be a list of strings representing the list of recipes to apply to
the node when converging.

```yaml
host1.mycompany.com:
  itamae:
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

Very little bootstrapping is required for this configuration manager, as itamae
requires no setup on the node site since the Ruby code in the recipes is
interpreted locally and not on the nodes. During bootstrapping, only the node
hostname will be set according to your chake configuration.

## See also

* **chake(1)**
