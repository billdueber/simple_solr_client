require 'simple_solr_client/schema/field_or_type'
class SimpleSolrClient::Schema
  class Field < Field_or_Type
    include Matcher

    attr_accessor :type_name, :type
    attr_reader :matcher


    def initialize(*args)
      super
      @dynamic = false
    end

    def xml_node(doc)
      Nokogiri::XML::Element.new('field', doc)
    end

    # We can only resolve the actual type in the presence of a
    # particular schema
    def resolve_type(schema)
      self.type = schema.field_type(self.type_name)
      self
    end


    # When we reset the name, make sure to re-derive the matcher
    # object
    def name=(n)
      @name    = n
      @matcher = derive_matcher(n)
    end

  end
end
