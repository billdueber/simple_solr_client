require 'simple_solr/schema/analysis'

# A basic field type
#
# We don't even try to represent the analysis chain; just store the raw
# xml
#
# We also, in blatent disregard for separation of concerns and encapsulation,
# put in a place to store a core. This is filled when the fieldtype is added
# to the schema via add_field_type, so we can have access to the
# analysis chain.

class SimpleSolrClient::Schema
  class FieldType < Field_or_Type
    include SimpleSolrClient::Schema::Analysis

    attr_accessor :xml, :solr_class, :core

    def initialize(*args)
      super
      @xml = nil
    end

    # Make sure the type is never set, so we don't get stuck
    # trying to find a type's "type"
    def type
      nil
    end

    # Create a Nokogiri node out of the currently-set
    # element attributes (indexed, stored, etc.) and the
    # XML
    def xml_node(doc)
      ft          = Nokogiri::XML::Element.new('fieldType', doc)
      ft['class'] = self.solr_class
      xmldoc      = Nokogiri.XML(xml)
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


