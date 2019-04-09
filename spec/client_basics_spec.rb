require 'minitest_helper'

describe SimpleSolrClient::Client do

  before do
    @client = TestClient.instance.client
  end
  it "creates a new object" do
    @client.base_url.must_equal ENV['TEST_SOLR_URL']
  end

  it "strips off a trailing slash for base_url" do
    c = SimpleSolrClient::Client.new( ENV['TEST_SOLR_URL'])
    c.base_url.must_equal ENV['TEST_SOLR_URL']
  end

  it "constructs a url with no args" do
    @client.url.must_equal ENV['TEST_SOLR_URL']
  end

  it "constructs a URL with args" do
    @client.url('admin', 'ping').must_equal "#{ENV['TEST_SOLR_URL']}/admin/ping"
  end


end
