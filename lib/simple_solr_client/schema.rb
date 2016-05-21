require 'simple_solr_client/schema/matcher'
require 'simple_solr_client/schema/copyfield'
require 'simple_solr_client/schema/field'
require 'simple_solr_client/schema/dynamic_field'
require 'simple_solr_client/schema/field_type'

class SimpleSolrClient::Schema
  # A simplistic representation of a schema


  def initialize(core)
    @core           = core
    @fields         = {}
    @dynamic_fields = {}
    @copy_fields    = Hash.new { |h, k| h[k] = [] }
    @field_types    = {}
    self.load
  end


  def fields
    @fields.values.map { |x| x.resolve_type(self) }
  end

  def field(n)
    @fields[n].resolve_type(self)
  end

  def dynamic_fields
    @dynamic_fields.values.map { |x| x.resolve_type(self) }
  end

  def dynamic_field(n)
    @dynamic_fields[n].resolve_type(self)
  end

  def copy_fields_for(n)
    @copy_fields[n]
  end

  def copy_fields
    @copy_fields.values.flatten
  end

  def add_field(f)
    @fields[f.name] = f
    field(f.name)
  end

  def drop_field(str)
    @fields.delete(str)
    self
  end


  def field_types
    @field_types.values
  end

  def field_type(k)
    @field_types[k]
  end


  # When we add dynamic fields, we need to keep them sorted by
  # length of the key, since that's how they match
  def add_dynamic_field(f)
    raise "Dynamic field should be dynamic and have a '*' in it somewhere; '#{f.name}' does not" unless f.name =~ /\*/
    @dynamic_fields[f.name] = f

    @dynamic_fields = @dynamic_fields.sort { |a, b| b[0].size <=> a[0].size }.to_h

  end

  def drop_dynamic_field(str)
    @dynamic_fields.delete(str)
    self
  end

  def add_copy_field(f)
    cf = @copy_fields[f.source]
    cf << f
  end

  def drop_copy_field(str)
    @copy_fields.delete(str)
    self
  end

  def add_field_type(ft)
    ft.core = @core
    @field_types[ft.name] = ft
  end

  def drop_field_type(str)
    @field_types.delete(str)
    self
  end


  # For loading, we get the information about the fields via the API,
  # but grab an XML document for modifying/writing
  def load
    load_explicit_fields
    load_dynamic_fields
    load_copy_fields
    load_field_types
  end


  def load_explicit_fields
    @fields = {}
    @core.get('schema/fields')['fields'].each do |field_hash|
      add_field(Field.new_from_solr_hash(field_hash))
    end
  end

  def load_dynamic_fields
    @dynamic_fields = {}
    @core.get('schema/dynamicfields')['dynamicFields'].each do |field_hash|
      f = DynamicField.new_from_solr_hash(field_hash)
      if @dynamic_fields[f.name]
        raise "Dynamic field '#{f.name}' defined more than once"
      end
      add_dynamic_field(f)
    end
  end

  def load_copy_fields
    @copy_fields = Hash.new { |h, k| h[k] = [] }
    @core.get('schema/copyfields')['copyFields'].each do |cfield_hash|
      add_copy_field(CopyField.new(cfield_hash['source'], cfield_hash['dest']))
    end
  end

  def load_field_types
    @field_types = {}
    @core.get('schema/fieldtypes')['fieldTypes'].each do |fthash|
      ft        = FieldType.new_from_solr_hash(fthash)
      add_field_type(ft)
    end
  end

  def reload
    @core.reload
  end
end




