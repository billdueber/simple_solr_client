module SimpleSolr
  # A simplistic representation of a schema
  class Schema

    module Matcher
      def derive_matcher(src )
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

    attr_reader :fields, :dfields, :field_types, :copy_fields

    def initialize(core)
      @core = core
      @fields = {}
      @dfields = {}
      @copy_fields = Hash.new {|h,k| h[k] = []}
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


    def load
      load_explicit_fields
      load_dynamic_fields
      load_copy_fields
    end


    def load_explicit_fields
      @fields = {}
      @core.get('schema/fields')['fields'].each do |field_hash|
        add_field(Field.new_from_hash(field_hash))
      end
    end

    def load_dynamic_fields
      @dfields = {}
      @core.get('schema/dynamicfields')['dynamicFields'].each do |field_hash|
        f = DynamicField.new_from_hash(field_hash)
        if @dfields[f.name]
          raise "Dynamic field '#{f.name}' defined more than once"
        end
        add_dynamic_field(f)
      end
    end

    def load_copy_fields
      @copy_fields = Hash.new {|h,k| h[k] = []}
      @core.get('schema/copyfields')['copyFields'].each do |cfield_hash|
        add_copy_field(CopyField.new(cfield_hash['source'], cfield_hash['dest']))
      end
    end


    def save

    end


    # A field, and some of its info
    class Field_or_Type
      attr_accessor :name, :stored, :multi, :indexed,
                    :sort_missing_last,
                    :in_default_schema

      def initialize(name = nil)
        @name = nil
      end

      def stored?
        @stored
      end

      def multi?
        @mulit
      end

      def indexed?
        @indexed
      end


    end

    class Field < Field_or_Type
      include Matcher

      attr_accessor :type_name, :copy_to, :dynamic

      def initialize(name = nil)
        super
        @dynamic = false
        @copy_to = []
      end

      def name=(n)
        @name = n
        @matcher = derive_matcher(n)
      end

      def self.new_from_hash(h)
        f                   = self.new
        f.name              = h['name']
        f.type_name         = h['type']
        f.stored            = h['stored']
        f.indexed           = h['indexed']
        f.multi             = h['multiValued']
        f.sort_missing_last = h['sortMissingLast']
        f
      end

      def dynamic?
        dynamic
      end

    end


    class DynamicField < Field

      def initialize(name = nil)
        super
        @dynamic = true
      end
    end



    # A basic field type
    #
    # We don't even try to represent the analysis chain; just store the raw
    # xml
    class FieldType < Field_or_Type
      attr_accessor :xml, :class

      def initialize(name=nil, xml =nil)
        super(name)
        @xml = xml
      end
    end

    class CopyField
      include Matcher

      attr_accessor :source, :dest
      def initialize(source, dest)
        self.source = source
        @dest = dest
        @matcher = derive_matcher(source)
      end

      def source=(s)
        @matcher = derive_matcher(s)
        @source = s
      end


    end


  end
end
