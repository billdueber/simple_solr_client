# SimpleSolr

[Note: still woefully incomplete, but in the spirit of "release early,
even if it's bad", here it is.]

A Solr client specifically designed to try to help you test what the heck
solr is actually doing.

Most useful when running on the same machine as the solr install, but
still useful even when you're not.

## Example Usage

```ruby

# A "client" points to a running solr, independent of the particular core
# You get a core from it.

client = SimpleSolr::Client.new('http://localhost:8983/solr')
core = client.core('core1') # must already exist!
core.url #=> "http://localhost:8983/solr/core1"

core.name #=> 'core1'
core.number_of_documents #=> 7
core.instance_dir #=> "/Users/dueberb/devel/java/solr/example/solr/collection1/"
core.schema_file #=> <path>/<to>/<schema.xml>

# Remove all the docs
core.clear

# Add
h1 = {:id => 'b', :name=>"Bill Dueber"}
h2 = {:id => 'd', :name=>"Danit Brown"}
h3 = {:id => 'z', :name=>"Ziv Brown Dueber"}

core.add_docs(h1)

core.number_of_documents #=> 0? By why? Oh...
core.commit
core.number_of_documents #=> 1

# You can chain many core operations
core.clear.add_docs([h1,h2, h3]).commit.optimize.number_of_documents #=> 3

# Only the most basic querying is possible



```



## Motivation

Solr is complex.

It's complex enough, and fuddles with enough edge cases, that reading
the documentation and/or the code doesn't get me the understanding
that I want. I wanted a way to test what solr is actually doing, and
this library is a way for me to start to do that.

# Features
  *



## Installation

    $ gem install simple_solr


## Contributing

1. Fork it ( https://github.com/billdueber/simple_solr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
