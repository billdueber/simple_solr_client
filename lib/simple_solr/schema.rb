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

    attr_reader :fields, :field_types, :copy_fields

    def initialize
      @fields      = {}
      @copy_fields = []
      @field_types = {}

    end

    def explicit_fields
      @fields.values.find_all {|x| x.explicit?}
    end

    def dynamic_fields
      @fields.values.find_all {|x| x.dynamic?}
    end

    def add_field(f, in_default_schema = false)
      @fields[f.name] = f
      f.in_default_schema = true if in_default_schema
    end

    def add_field_type(fd, in_default_schema = false)
      @field_types[fd.name] = fd
    end


    def _add_explicit_fields_from_solr_resp(resp_from_schema_fields)
      resp_from_schema_fields['fields'].each { |fh| add_field(Field.new_from_hash(fh), :in_default_schema) }
    end

    def _add_dynamic_fields_from_solr_resp(resp_from_schema_dynamicfields)
      resp_from_schema_dynamicfields['dynamicFields'].each { |fh| add_field(Field.new_from_hash(fh, :dynamic), :in_default_schema) }
    end

    def _add_copy_fields_from_solr_resp(resp_from_schema_copyfields)
      resp_from_schema_copyfields['copyFields'].each {|h| @copy_fields << CopyField.new(h['source'], h['dest'])}
    end


    # A field, and some of its info
    class Field_or_Type
      attr_accessor :name, :stored, :multi, :indexed,
                    :sort_missing_last,
                    :in_default_schema

      def initialize(name = nil)
        @name = nil
      end

      def hello
        "Hello"
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

      attr_accessor :type_name, :dynamic, :copy_to,

      def initialize(name = nil)
        super
        @copy_to = []
      end

      def name=(n)
        @name = n
        @matcher = derive_matcher(n)
      end

      def self.new_from_hash(h, dynamic = false)
        f                   = self.new
        f.name              = h['name']
        f.type_name         = h['type']
        f.stored            = h['stored']
        f.indexed           = h['indexed']
        f.multi             = h['multiValued']
        f.sort_missing_last = h['sortMissingLast']
        f.dynamic           = dynamic
        f
      end

      def dynamic?
        dynamic
      end

      def explicit?
        !dynamic
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
