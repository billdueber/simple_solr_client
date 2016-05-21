$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simple_solr_client'
require 'minitest/autorun'
require 'minitest/spec'

require 'singleton'

ENV['TEST_SOLR_URL'] ||= 'http://localhost:8983/solr'
ENV['TEST_SOLR_CORE'] ||= 'simple_solr_client_core'

class TestClient
  include Singleton
  attr_reader :client, :core
  def initialize
    @client = SimpleSolrClient::Client.new ENV['TEST_SOLR_URL']
  end
end

class TempCore
  include Singleton
  attr_reader :client
  def initialize
    @client = TestClient.instance.client
    @tempcores = {}
    Minitest.after_run { @client.unload_temp_cores }
  end

  def core(name)
    @tempcores[name] ||= @client.temp_core
    @tempcores[name]
  end
end

