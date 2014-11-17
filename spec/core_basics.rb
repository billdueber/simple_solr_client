require 'minitest_helper'

describe SimpleSolr::Client do

  before do
    @client = TestClient.instance.client
    @core = @client.core('core1')
  end
  it "creates a new object" do
    @core.base_url.must_equal 'http://localhost:8983/solr/core1'
  end

  it "constructs a url with no args" do
    @core.url.must_equal 'http://localhost:8983/solr/core1'
  end

  it "constructs a URL with args" do
    @core.url('admin', 'ping').must_equal 'http://localhost:8983/solr/core1/admin/ping'
  end


end
