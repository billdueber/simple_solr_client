require 'minitest_helper'

describe SimpleSolrClient::Core do

  before do
    @core = TempCore.instance.core('core_basics')
  end
  it "creates a new object" do
    @core.base_url.must_equal ENV['TEST_SOLR_URL']
  end

  it "constructs a url with no args" do
    @core.url.must_equal "#{ENV['TEST_SOLR_URL']}/#{@core.name}"
  end

  it "constructs a URL with args" do
    @core.url('admin', 'ping').must_equal "#{ENV['TEST_SOLR_URL']}/#{@core.name}/admin/ping"
  end


end
