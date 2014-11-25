# SimpleSolr

[Note: still woefully incomplete, but in the spirit of "release early,
even if it's bad", here it is.]

A Solr client specifically designed to try to help you test what the heck
solr is actually doing.

Most useful when running on the same machine as the solr install, but
still useful even when you're not.


## Motivation

Solr is complex.

It's complex enough, and fuddles with enough edge cases, that reading
the documentation and/or the code doesn't get me the understanding
that I want. I wanted a way to test what solr is actually doing, and
this library is a way for me to start to do that in a fashion that's
more convenient that doing everything "by hand" in the admin dashboard.

# Features:

  * Basic add/delete/query
  * Commit/optimize/clear an index
  * Reload a core after editing/adjusting a config file
  * Inspect lists of fields, dynamicFields, copyFields, and
    fieldTypes
  * Determine which fields (and their properties) would be
    created when a given field name is indexed, taking into
    account dynamic fields and copyField directives.

Additional features when running against a localhost solr:
  * Spin up a temporary core to play with
  * Add/remove fields, dynamic_fields, copy_fields, and field types
    on the fly
  *

## Basic add/delete/query

Right now, it supports only the most basic add/delete/query operations.
Adding in support for more complex queries is on the TODO list, but took
a back seat to dealing with the schema.


```ruby

# A "client" points to a running solr, independent of the particular core
# You get a core from it.

client = SimpleSolr::Client.new('http://localhost:8983/solr')
core = client.core('core1') # must already exist!
core.url #=> "http://localhost:8983/solr/core1"

core.name #=> 'core1'
core.number_of_documents #=> 7, what was in there already
core.instance_dir #=> "/Users/dueberb/devel/java/solr/example/solr/collection1/"
core.schema_file #=> <path>/<to>/<schema.xml>

# Remove all the indexed documents and (automatically) commit
core.clear

# Add documents
#
# name_t is a text_general, multiValued, indexed, stored field
h1 = {:id => 'b', :name_t=>"Bill Dueber"}
h2 = {:id => 'd', :name_t=>"Danit Brown"}
h3 = {:id => 'z', :name_t=>"Ziv Brown Dueber"}

core.add_docs(h1)

core.number_of_documents #=> 0? But why? Oh, right...
core.commit
core.number_of_documents #=> 1  There we go

# You can chain many core operations
core.clear.add_docs([h1,h2, h3]).commit.optimize.number_of_documents #=> 3

# only the most basic querying is currently supported
# Result of a query is a QueryResponse, which contains a list of Document
# objects, which respond to ['fieldname']

core.all.size #=> 3
core.all.map{|d| d['name_t']} #=> [['Bill Dueber'], ['Danit Brown'], ['Ziv Brown Dueber']]

# Simple field/value search
docs = core.fv_search(:name_t, 'Brown')
docs.class #=>  SimpleSolr::Response::QueryResponse

docs.size #=> 2
docs..map{|d| d['name_t']} #=> [['Danit Brown'], ['Ziv Brown Dueber']]

# Special-case id/score
docs.first.id #=> 'd'
docs.first.score #=> 0.625

# Figure out where documents fall
docs = core.fv_search(:name_t, 'Brown Dueber')
docs.size #=> 3

# "Ziv Brown Dueber" contains both search terms, so should come first

docs.rank('z') #=> 1 (check by id)
docs.rank('z') < docs.rank('b') #=> true

# Of course, we can do it by score
docs.score('z') > docs.score('d')

# In addition to #clear, we can delete by simple query
core.delete('name_t:Dueber').commit.number_of_documents #=> 1


```

## Introspection








## Installation

    $ gem install simple_solr


## Contributing

1. Fork it ( https://github.com/billdueber/simple_solr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
