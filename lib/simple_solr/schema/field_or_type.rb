# Base class for Field/DynamicField/FieldType
module SimpleSolr
  class Schema
    class Field_or_Type
      attr_accessor :name,
                    :type_name
      attr_writer :indexed,
                  :stored,
                  :multi,
                  :sort_missing_last,
                  :precision_step,
                  :position_increment_gap

      # Take in a hash, and set anything in it that we recognize.
      # Sloppy from a data point of view, but make fore easy
      # duplication and creation from xml/json

      def initialize(h={})
        h.each_pair do |k, v|
          begin
            self[k] = v
          rescue
          end

        end
      end


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

      # Allow access to methods via [], for easy looping
      def [](k)
        self.send(k.to_sym)
      end

      def []=(k, v)
        self.send("#{k}=".to_sym, v)
      end


      # Make a hash out of it, for easy feeding back into another call to #new
      def to_h
        h = {}
        instance_variables.each do |iv|
          h[iv.to_s.sub('@', '')] = instance_variable_get(iv)
        end
        h
      end

    end
  end
end
