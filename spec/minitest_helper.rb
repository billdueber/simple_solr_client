$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simple_solr'
require 'minitest/spec'
require 'minitest/autorun'
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'singleton'

ENV['TEST_SOLR_URL'] ||= 'http://localhost:8983/solr'
ENV['TEST_SOLR_CORE'] ||= 'core1'

class TestClient
  include Singleton
  attr_reader :client, :core
  def initialize
    @client = SimpleSolr::Client.new ENV['TEST_SOLR_URL']
    @core = @client.core ENV['TEST_SOLR_CORE']
  end
end

class TempCore
  include Singleton
  attr_reader :core, :client
  def initialize
    @client = TestClient.instance.client
    @core = @client.temp_core
    Minitest.after_run { @core.unload }

  end
end

