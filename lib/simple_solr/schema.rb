require 'oga'

class SimpleSolr::Schema
  # A simplistic representation of a schema

  module Matcher
    def derive_matcher(src)
      if src =~ /\A\*(.*)/
        Regexp.new("\\A(.*)#{Regexp.escape($1)}\\Z")
      else
        src
      end
    end

    def matches(s)
      @matcher === s
    end

  end

  attr_reader :fields, :dfields, :field_types, :copy_fields, :xmldoc

  def initialize(core)
    @core        = core
    @fields      = {}
    @dfields     = {}
    @copy_fields = Hash.new { |h, k| h[k] = [] }
    @field_types = {}
    self.load
  end

  def add_field(f)
    @fields[f.name] = f
  end

  def add_dynamic_field(f)
    @dfields[f.name] = f
  end

  def add_copy_field(f)
    cf = @copy_fields[f.source]
    cf << f
  end


  # For loading, we get the information about the fields via the API,
  # but grab an XML document for modifying/writing
  def load
    @xmldoc = Oga.parse_xml(@core.raw_get_content('admin/file', {:file=>'schema.xml'}))
    load_explicit_fields
    load_dynamic_fields
  end


  def load_explicit_fields
    @fields = {}
    @xmldoc.css('field').each do |xmlf|
      add_field(Field.new_from_oga_node(xmlf))
    end
  end

  def load_dynamic_fields
    @dfields = {}
    @xmldoc.css('dynamicField').each do |xmlf|
      f = DynamicField.new_from_oga_node(xmlf)
      if @dfields[f.name]
        raise "Dynamic field '#{f.name}' defined more than once"
      end
      add_dynamic_field(f)
    end

  end



  def write

  end

  def reload
    write
    @core.reload
  end


  # A field, and some of its info
  # Use a struct because it'll make it easier to
  # set things programmatically.

  Field_or_Type = Struct.new(
      :name, :stored, :multi, :indexed, :type_name,
      :sort_missing_last
  )


  class Field < Field_or_Type
    include Matcher

    attr_accessor :type_name
    attr_reader :matcher

    TEXT_ATTR_MAP = {
        :name => 'name',
        :type_name => 'type',
     }

    BOOL_ATTR_MAP = {
        :stored => 'stored',
        :indexed => 'indexed',
        :multi => 'multiValued',
        :sort_missing_last => 'sortMissingLast'
    }

    def initialize(name = nil, loaded_from_url = false)
      super
      @dynamic = false
      @copy_to = []
    end

    def name=(n)
      @name    = n
      @matcher = derive_matcher(n)
    end


    # We need to convert the string 'true' to a true value
    # and vice-versa
    def string_to_bool(s)
      return nil if s.nil?
      s == 'true'
    end

    def bool_to_string(b)
      return nil if b.nil?
      b ? "true" : "false"
    end


    def self.new_from_oga_node(n)
      f = self.new

      TEXT_ATTR_MAP.each_pair do |field, xmlattr|
        f[field] = n.attr(xmlattr).value if n.attr(xmlattr)
      end
      BOOL_ATTR_MAP.each_pair do |field, xmlattr|
        f[field] = f.string_to_bool n.attr(xmlattr).value if n.attr(xmlattr)
      end
      f
    end

    def to_oga_node
      e = Oga::XML::Element.new
      e.set('name', 'field')
      TEXT_ATTR_MAP.each_pair do |field, xmlattr|
        e.set(xmlattr, self[field]) unless self[field].nil?
      end
      BOOL_ATTR_MAP.each_pair do |field, xmlattr|
        e.set(xmlattr, bool_to_string(self[field])) unless self[field].nil?
      end
      e
    end
  end



  class DynamicField < Field

    def initialize(name = nil, loaded_from_url = false)
      super
      @dynamic = true
    end

    # Dynamic fields are basically the same as regular fields,
    # but with a different tag

    def to_oga_node
      e = super
      e.name = 'dynamicField'
    end

  end


  # A basic field type
  #
  # We don't even try to represent the analysis chain; just store the raw
  # xml
  class FieldType < Field_or_Type
    attr_accessor :xml, :class

    def initialize(name=nil, xml =nil, loaded_from_url = false)
      super(name)
      @xml = xml
    end
  end

  class CopyField
    include Matcher

    attr_accessor :source, :dest

    def initialize(source, dest, loaded_from_url = false)
      self.source = source
      @dest       = dest
      @matcher    = derive_matcher(source)
    end

    def source=(s)
      @matcher = derive_matcher(s)
      @source  = s
    end


  end


end

