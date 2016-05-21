# # Pre-define the inheritance so Ruby doesn't complain
# # on import.

require 'simple_solr_client/schema'

require 'simple_solr_client/client.rb'
require 'simple_solr_client/core/admin'
require 'simple_solr_client/core/core_data'
require 'simple_solr_client/core/index'
require 'simple_solr_client/core/search'

# We already said that Core is a subclass of Client in
# the client.rb file, to avoid circular references

module SimpleSolrClient
  class Core
    include SimpleSolrClient::Core::Admin
    include SimpleSolrClient::Core::CoreData
    include SimpleSolrClient::Core::Index
    include SimpleSolrClient::Core::Search


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
      @schema ||= SimpleSolrClient::Schema.new(self)
    end

  end
end
