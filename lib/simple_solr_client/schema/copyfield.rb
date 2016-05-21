require 'simple_solr_client/schema/matcher'

class SimpleSolrClient::Schema::CopyField
  include SimpleSolrClient::Schema::Matcher

  attr_accessor :dest
  attr_reader   :source

  def initialize(source, dest)
    self.source   = source
    @dest         = dest
    @matcher      = derive_matcher(source)
    @dest_matcher = derive_matcher(dest)
  end

# What name will we get from a matching thing?
  def dynamic_name(s)
    return @dest unless @dest =~ /\*/

    m = @matcher.match(s)
    if m
      prefix = m[1]
      return @dest.sub(/\*/, prefix)
    end
    nil

  end

  def source=(s)
    @matcher = derive_matcher(s)
    @source  = s
  end


end
