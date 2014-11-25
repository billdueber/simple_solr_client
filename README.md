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

  * Basic add/delete/query
  * Commit/optimize/clear an index
  * Reload a core after editing/adjusting a config file
  * Inspect lists of fields, dynamicFields, copyFields, and
    fieldTypes
  * Determine which fields (and their properties) would be
    created when a given field name is indexed, taking into
    account dynamicField and copyField directives.
  * Get list of the tokens that would be created if you
    send a string to a paricular fieldType (like in the
    solr admin analysis page)
  * Spit a modified schema object back out as xml for
    saving somewhere if you'd like

Additional features when running against a localhost solr:
  * Spin up a temporary core to play with
  * Add/remove fields, dynamic_fields, copy_fields, and field types
    on the fly and save them back, ready for a reload
  * Create temporary cores for doing testing



## Basic add and delete of documents, and simple queries

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

# All bring back all documents up to the page limit
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

## The `schema` object

Each core exposes a `schema` object that allows you to find out about
the fields, copyfields, and field types, and (on localhost) muck
with the system on the fly.

The schema object is initially created by using the admin api to
get lists of fields and field types, and the XML for the field types
is derived by parsing out the schema.xml returned by the api call. Solr
does *not* expand entities in the returned XML, so if you have `system`
entities (e.g., you're including stuff off of disk), simplesolr won't
get that text and things will likely blow up.


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

Internally I call these "explicit_fields" as opposed to dynamic fields.

```
f = schema.field('id')
f.name #=> 'id'
f.type.name #=> 'string'
f.type.solr_class #=> 'solr.StrField'

# Basic attributes
# These will fall back on the fieldType if not defined for a
# particular field.

f.stored  #=> true
f.indexed #=> true
f.multi   #=> nil # defined on neither field 'id' or fieldType 'string'

# We implement a matcher, which is just string equality
f.matches('id') #=> true
f.matches('id_t') #=>false

# You can add fields, and save it back if you're on
# localhost

schema.add_field Field.new(:name=>'format', :type_name=>'string', :multi=>true, :stored=>false, :indexed=>true)

schema.write; core.reload # only on localhost

core.schema.field('format').type.name #=> 'string'

```

### Dynamic fields

The rule Solr uses for dynamic fields is "longest one wins"
Right now, I'm only handling _leading_ asterisks, so `*_t` will
work, but `text_*` will not.

```
schema.dynamic_fields.size #=> 23
f = schema.dynamic_field('*_t') #=> SimpleSolr::Schema::DynamicField
f.name #=> '*_t')
f.type.name #=> 'text_general'
f.stored #=> true
f.matches('name_t') #=> true
f.matches('name_t_i') #=> false
f.matches('name') #=> false

# Dynamic Fields can also be added
schema.add_dynamic_field(:name=>"*_f", :type_name=>'float')

```

### Copy Fields

CopyFields are a different beast: they only have a source and a dest, and
they can have multiple targets. For that reason, the interface is slightly
different (`#copy_fields_for` instead of just `#copy_field`)

```

# <copyField source="*_t_s", dest="*_t"/>
# <copyField source="*_t_s", dest="*_s"/>

cfs = schema.copy_fields_for('*_ts')
cfs.size #=> 2
cfs.map(&:dest) #=> ["*_t", "*_s"]

cf = SimpleSolr::Schema::CopyField.new('title', 'allfields')
cf.source #=> 'title'
cf.dest  #=>  'allfields'

schema.add_copy_field(cf)
```


### Field Types

Field Types are created by getting data from the API and also
parsing XML out of the schema.xml (for later creating a new
schema.xml if you'd like).

You can also ask a field type how it would tokenize an input
string via indexing or querying.


FieldTypes _should_ be able to, say, report their XML serialization even
when outside of a particular schema object, but right now that doesn't
work. If you make changes to a field type, the only way to see the new
serialization is to call `schema.to_xml` on whichever schema you added
it to via `schema.add_field_type(ft)`



```ruby

schema.field_types.size #=> 23
ft = schema.field_type('text') #=> SimpleSolr::Schema::FieldType
ft.name #=> 'text'
ft.solr_class #=> 'solr.TextField'
ft.multi #=> true
ft.stored #=> true
ft.indexed #=> true
# etc.

newft = SimpleSolr::Schema::FieldType.new_from_xml(xmlstring)
schema.add_field_type(newft)

ft.name #=> text
ft.query_tokens "Don't forget me when I'm getting H20"
  #=> ["don't", "forget", "me", "when", "i'm", ["getting", "get"], "h20"]

ft.index_tokens 'When it rains, it pours'
  #=> ["when", "it", ["rains", "rain"], "it", ["pours", "pour"]]

```


## What will I get if I index a field named `str`?

Dynamic- and copy-fields are very convenient, but it can make it hard to
figure out what you're actually going to get in your indexed and
stored fields. I started thinking about this [at the end of this blog post](http://robotlibrarian.billdueber.com/2014/10/schemaless-solr-with-dynamicfield-and-copyfield/)

`schema.resulting_fields(str)` will take the field name given and
figure out what fields would be generated, returning an array of field
objects (which are created wholesale if need be due to dynamicFields or
copyFields).

```ruby
rs = schema.resulting_fields('name_t_s')
rs.size #=> 3

rs.map{|f| [f.name, f.type.name]}
  #=> [["name_t_s", "ignored"], ["name_t", "text"], ["name", "string"]]

rs.find_all{|f| f.stored}.map(&:name) #=> ["name"]
rs.find_all{|f| f.indexed}.map(&:name) #=> ['name_t']



```


## Saving/reloading a changed schema

Whether you change a solr install via editing a text file or
by using `schema.write`, you can always reload a core.

```ruby
core.reload
```

If you're working on localhost, you can make programmatic changes
to the schema and then ask for a write/reload cycle. It uses the API
to find the path to the schema.xml file and overwrites it.

```ruby

schema = core.schema
core.add_field Field.new(:name=>'price', :type_name=>'float')
schema.write
schema = core.reload.schema
```


## Installation

    $ gem install simple_solr


## Contributing

1. Fork it ( https://github.com/billdueber/simple_solr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
