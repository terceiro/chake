# chake

Simple host management with chef and rake. No chef server required.

## Installation

    $ gem install chake

## Usage

Require chake on your `Rakefile`:

```ruby
require 'chake'
```

Initializing the repository:

    $ rake init


Important files that are generated:

```
config.rb
nodes.yaml
config/
config/roles/
cookbooks/
cookbooks/myhost/
cookbooks/myhost/recipes/
cookbooks/myhost/recipes/default.rb

```

* `nodes.yaml`, where you will list the hosts you will be managing.
* a `cookbooks` directory where you will store your cookbooks. A sample
  cookbook called "myhost" is created, but feel free to remove it and add
  actual cookbooks.


Sample `nodes.yaml`:

```yaml
host1.mycompany.com:
    run_list:
        - recipe[common]
        - recipe[webserver]
host2.mycompany.com:
    run_list:
        - recipe[common]
        - recipe[mailserver]
```

Check the output of `rake -T` to see what else you can do.

## Contributing

1. Fork it ( http://github.com/terceiro/chake/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
