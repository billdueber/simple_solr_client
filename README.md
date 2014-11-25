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
that I feel I need.

If I were smarter, maybe I wouldn't need something like this.

I wanted a way to test what solr is actually doing, and
this library is a way for me to start to do that in a fashion that's
more convenient that doing everything "by hand" in the admin dashboard
or running queries via URLs in my browser or using curl.

I wanted a way to figure out what fields (of what types) are being created,
how things were being  tokenized, etc., but all within the comfort of a test
suite that I could run against solr configurations to make sure things
weren't breaking when I made changes. I wanted to build up a structure around relevance
ranking tests (still coming, sadly) and quickly swap out different
configs to make sure it all works as I expect.

So: a simple solr library, with more exposure than most of what's out there
to the solr administration API and the introspection/analysis it affords.

# Features:

  * [Basic add/delete/query](#basic-add_delete_query)
  * Commit/optimize/clear an index
  * Reload a core after editing/adjusting a config file
  * Inspect lists of fields, dynamicFields, copyFields, and
    fieldTypes
  * Determine which fields (and their properties) would be
    created when a given field name is indexed, taking into
    account dynamic fields and copyField directives.
  * Get list of the tokens that would be created if you
    send a string to a paricular fieldType (like in the
    solr admin analysis page)

Additional features when running against a localhost solr:
  * Spin up a temporary core to play with
  * Add/remove fields, dynamic_fields, copy_fields, and field types
    on the fly


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

# Special-case id/score as regular methods
docs.first.id #=> 'd'
docs.first.score #=> 0.625

# Figure out where documents fall. "Ziv Brown Dueber" contains both
# search terms, so should come first
docs = core.fv_search(:name_t, 'Brown Dueber')
docs.size #=> 3

docs.rank('z') #=> 1 (check by id)
docs.rank('z') < docs.rank('b') #=> true

# Of course, we can do it by score
docs.score('z') > docs.score('d')

# In addition to #clear, we can delete by simple query
core.delete('name_t:Dueber').commit.number_of_documents #=> 1


```

## Introspection/Analysis

Each core exposes a `schema` object that allows you to find out about
the fields, copyfields, and field types, and (on localhost) muck
with the system on the fly.

```ruby

# Get a list of cores
client.cores #=> ['core1']
core = client.core('core1')

# Get an object representing the schema.xml file
schema = core.schema #=> SimpleSolr::Schema object

# Get lists of field, dynamicFields, copyFields, and fieldTypes
# all as SimpleSolr::Schema::XXX objects

explicit_fields = schema.fields
dynamic_fields  = schema.dynamic_fields
copy_fields     = schema.copy_fields
field_types     = schema.field_types

```

### Regular fields

Internally I call these "explicit_fields" as opposed to

f = schema.field('id')
f.name #=> 'id'
f.type.name #=> 'string'
f.type.solr_class #=> 'solr.StrField'

# Basic atributes
f.stored  #=> true
f.indexed #=> true
f.multi   #=> nil

f.matches



```








## Installation

    $ gem install simple_solr


## Contributing

1. Fork it ( https://github.com/billdueber/simple_solr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
