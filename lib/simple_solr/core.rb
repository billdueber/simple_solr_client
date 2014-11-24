# Pre-define the inheritance so Ruby doensn't complain
# on import.
require 'simple_solr/client'
require 'simple_solr/schema'
module SimpleSolr
  class Core < Client
  end
end


require 'simple_solr/core/admin'
require 'simple_solr/core/core_data'
require 'simple_solr/core/index'
require 'simple_solr/core/search'

class SimpleSolr::Core


  include SimpleSolr::Core::Admin
  include SimpleSolr::Core::CoreData
  include SimpleSolr::Core::Index
  include SimpleSolr::Core::Search


  attr_reader :core
  alias_method :name, :core

  def initialize(url, core)
    super(url)
    @core = core
  end


  # Override #url so we're now talking to the core
  def url(*args)
    [@base_url, @core, *args].join('/').chomp('/')
  end

  # Send JSON to this core's update/json handler
  def update(object_to_post, response_type = nil)
    post_json('update/json', object_to_post, response_type)
  end

  def schema
    @schema ||= SimpleSolr::Schema.new(self)
  end

end


