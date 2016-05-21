require 'minitest_helper'

describe "Schema" do

  SS = SimpleSolrClient::Schema # convenience

  before do
    @core   = TempCore.instance.core('schema_spec')
    @schema = @core.schema
  end

  describe "the id field" do
    it "finds it" do
      @schema.field('id').name.must_equal 'id'
    end

    it "has a type name of string" do
      @schema.field('id').type_name.must_equal 'string'
    end

    it "has the string type" do
      @schema.field('id').type.must_equal @schema.field_type('string')
    end

    it "matches on exact match" do
      @schema.field('id').matches('id').must_equal true
    end

    it "doesn't match on inexact match" do
      @schema.field('id').matches('testid').must_equal false
    end

  end

  describe "the _i dynamic field" do
    it "finds it" do
      @schema.dynamic_field('*_i').wont_be_nil
    end

    it "has type int" do
      @schema.dynamic_field("*_i").type.must_equal @schema.field_type('int')
    end

    it 'matches appropriates' do
      dfield  = @schema.dynamic_field('*_i')
      dfield.matches('test_i').must_equal true
      dfield.matches('test_s_i').must_equal true
      dfield.matches('test_i_s').must_equal false
    end
  end


end

