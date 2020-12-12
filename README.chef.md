chake-chef(7) -- configure chake nodes with chef-solo
=====================================================

## Description

This configuration manager will allow you to manage nodes by running
**chef-solo(1)** on each remote node.

When `chake init` runs, the following chef-specific files will be created:

A brief explanation of the created files that are specific to **chef**:

* `config.rb`: contains the chef-solo configuration. You can modify it, but
  usually you won't need to.
* `config/roles`: directory is where you can put your role definitions.
* `cookbooks`: directory where you will store your cookbooks. A sample cookbook
  called "basics" is created, but feel free to remove it and add actual
  cookbooks.

## Configuration

Nodes can be configured to be managed with chef by having a `run_list` key in
their configuration:

```yaml
host1.mycompany.com:
  run_list:
    - role[server]
    - recipe[service1]
  service1:
    option1: "here we go"
```

Any extra configuration under `host1.mycompany.com` will be saved to a JSON file
and given to the chef-solo --node-json option in the command line. For example,
the above configuration will produce a JSON file that looks like this:

```json
{
  "run_list": [
    "role[server]",
    "recipe[service1]"
  ]
  ,
  "service1": {
    "option1": "here we go"
  }
}
```

Inside Chef recipes, you can access those values by using the `node` object.
For example:

```ruby
template "/etc/service1.conf.d/option1.conf" do
  variables option1: node["option1"]
end
```

## Bootstrapping

The bootstrap process for _chef_ involves getting chef-solo installed. The
node hostname will also be set based on the hostname informed in the
configuration file.

## See also

* **chake(1)**
* <https://docs.chef.io/>
* <https://docs.chef.io/chef_solo.html>
