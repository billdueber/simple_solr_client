require 'nokogiri'
require 'pry'

require 'simple_solr/schema/matcher'
require 'simple_solr/schema/copyfield'

class SimpleSolr::Schema
  # A simplistic representation of a schema
  include SimpleSolr::Schema::Matcher

  attr_reader :xmldoc

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
  # lenght of the key, since that's how they match
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
    @field_types[ft.name] = ft
  end

  def drop_field_type(str)
    @field_types.delete(str)
    self
  end


  # For loading, we get the information about the fields via the API,
  # but grab an XML document for modifying/writing
  def load
    @xmldoc = Nokogiri.XML(@core.raw_get_content('admin/file', {:file => 'schema.xml'})) do |config|
      config.noent
    end
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
      type_name = ft.name
      attr      = "[@name=\"#{type_name}\"]"
      node      = @xmldoc.css("fieldType#{attr}").first || @xmldoc.css("fieldtype#{attr}").first
      unless node
        puts "Failed for type #{type_name}"
      end
      ft.xml    = node.to_xml
      add_field_type(ft)
    end
  end

  def clean_schema_xml
    d = @xmldoc.dup
    d.xpath('//comment()').remove
    d.css('field').remove
    d.css('fieldType').remove
    d.css('fieldtype').remove
    d.css('dynamicField').remove
    d.css('copyField').remove
    d.css('dynamicfield').remove
    d.css('copyfield').remove
    d.css('schema').children.find_all { |x| x.name == 'text' }.each { |x| x.remove }
    d
  end

  def to_xml
    # Get a clean schema XML document
    d = clean_schema_xml
    s = d.css('schema').first
    [fields, dynamic_fields, copy_fields, field_types].flatten.each do |f|
      s.add_child f.to_xml_node
    end
    d.to_xml
  end


  def write
    File.open(@core.schema_file, 'w:utf-8') do |out|
      out.puts self.to_xml
    end
  end

  def reload
    @core.reload
  end


  # Figuring out which fields are actually produced can be hard:
  #   * If a non-dynamic field name matches, no dynamic_fields will match
  #   * The result of a copyField may match another dynamicField, but the
  #     result of *that* will not match more copyFields
  #   * dynamicFields are matched longest to shortest
  #
  # Suppose I have the following:
  #  dynamic *_ts => string
  #  dynamic *_t  => string
  #  dynamic *_s  => string
  #  dynamic *_ddd => string
  #
  #  copy    *_ts => *_t
  #  copy    *_ts => *_s
  #  copy    *_s  => *_ddd
  #
  # You might expect:
  #  name_ts => string
  #  name_ts copied to name_t => string
  #  name_ts copied to name_s => string
  #  name_s  copied to name_ddd => string
  #
  # ...giving us name_ts, name_t, name_s, and name_ddd
  #
  # What you'll find is that we don't get name_ddd, since
  # name_s was generated by a wildcard-enabled copyField
  # and that's where things stop.
  #
  # However, if you explicitly add a field called
  # name_s, it *will* get copied to name_ddd.
  #
  # Yeah. It's confusing.


  def first_matching_field(str)
    f = fields.find { |x| x.matches str } or first_matching_dfield(str)
  end

  def first_matching_dfield(str)
    df = dynamic_fields.find { |x| x.matches str }
    if df
      f        = Field.new(df.to_h)
      f[:name] = df.dynamic_name str
    end
    f

  end

  def resulting_fields(str)
    rv = []
    f  = first_matching_field(str)
    rv << f
    copy_fields.each do |cf|
      if cf.matches(f.name)
        dname      = cf.dynamic_name(f.name)
        fmf        = Field.new(first_matching_field(dname).to_h)
        fmf[:name] = dname
        rv << fmf
      end
    end
    rv.uniq
  end


  # A field, and some of its info
  # Use a struct because it'll make it easier to
  # set things programmatically.

  class Field_or_Type
    attr_accessor :name,
                  :type_name
    attr_writer :indexed,
                :stored,
                :multi,
                :sort_missing_last,
                :precision_step,
                :position_increment_gap


    TEXT_ATTR_MAP = {
        :name                   => 'name',
        :type_name              => 'type',
        :precision_step         => 'precisionStep',
        :position_increment_gap => 'positionIncrementGap'
    }

    BOOL_ATTR_MAP = {
        :stored            => 'stored',
        :indexed           => 'indexed',
        :multi             => 'multiValued',
        :sort_missing_last => 'sortMissingLast'
    }

    # Do this little bit of screwing around to forward unknown attributes to
    # the assigned type, if it exists. Will just use regular old methods
    # once I get the mappings nailed down.
    [TEXT_ATTR_MAP.keys, BOOL_ATTR_MAP.keys].flatten.delete_if { |x| [:type_name].include? x }.each do |x|
      define_method(x) do
        local = instance_variable_get("@#{x}".to_sym)
        if local.nil?
          self.type[x] if self.type
        else
          local
        end
      end
    end

    def ==(other)
      if other.respond_to? :name
        name == other.name
      else
        name == other
      end
    end


    def self.new_from_solr_hash(h)
      f = self.new

      TEXT_ATTR_MAP.merge(BOOL_ATTR_MAP).each_pair do |field, xmlattr|
        f[field] = h[xmlattr]
      end
      # Set the name "manually" to force the
      # matcher
      f.name = h['name']

      f
    end


    # Reverse the process to get XML
    def to_xml_node(doc = nil)
      doc ||= Nokogiri::XML::Document.new
      xml = xml_node(doc)
      TEXT_ATTR_MAP.merge(BOOL_ATTR_MAP).each_pair do |field, xmlattr|
        iv = instance_variable_get("@#{field}".to_sym)
        xml[xmlattr] = iv unless iv.nil?
      end
      xml
    end

    def [](k)
      self.send(k.to_sym)
    end

    def []=(k, v)
      self.send("#{k}=".to_sym, v)
    end


    def to_h
      h = {}
      instance_variables.each do |iv|
        h[iv.to_s.sub('@', '')] = instance_variable_get(iv)
      end
      h
    end

    def initialize(h={})
      h.each_pair do |k, v|
        begin
          self[k] = v
        rescue
        end

      end
    end


  end


  class Field < Field_or_Type
    include Matcher

    attr_accessor :type_name, :type
    attr_reader :matcher


    def initialize(*args)
      super
      @dynamic = false
      @copy_to = []
    end

    def xml_node(doc)
      Nokogiri::XML::Element.new('field', doc)
    end

    # We can only resolve the actual type in the presense of a
    # particular schema
    def resolve_type(schema)
      self.type = schema.field_type(self.type_name)
      self
    end


    def name=(n)
      @name    = n
      @matcher = derive_matcher(n)
    end


  end


  class DynamicField < Field

    def initialize(*args)
      super
      @dynamic = true
    end

    def xml_node(doc)
      Nokogiri::XML::Element.new('dynamicField', doc)
    end

    # What name will we get from a matching thing?
    def dynamic_name(s)
      m = @matcher.match(s)
      if m
        m[1] << m[2]
      end
    end

  end


# A basic field type
#
# We don't even try to represent the analysis chain; just store the raw
# xml
  class FieldType < Field_or_Type
    attr_accessor :xml, :solr_class

    def initialize(*args)
      super
      @xml = nil
    end

    def type
      nil
    end

    def xml_node(doc)
      ft          = Nokogiri::XML::Element.new('fieldType', doc)
      ft['class'] = self.solr_class
      xmldoc = Nokogiri.XML(xml)
      unless xmldoc.children.empty?
        xmldoc.children.first.children.each do |c|
          ft.add_child(c)
        end
      end

      ft
    end

    def self.new_from_solr_hash(h)
      ft            = super
      ft.solr_class = h['class']
      ft
    end

    # Luckily, a nokogiri node can act like a hash, so we can
    # just re-use #new_from_solr_hash
    def self.new_from_xml(xml)
      ft     = new_from_solr_hash(Nokogiri.XML(xml).children.first)
      ft.xml = xml
      ft
    end
  end

end




