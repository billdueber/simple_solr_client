require 'httpclient'
require 'simple_solr/response/generic_response'
require 'simple_solr/schema'
require 'simple_solr/core_data'
require 'forwardable'
require 'delegate'
require 'securerandom'

module SimpleSolr

  # A Client talks to the Solr instance; use a SimpleSolr::Core to talk to a
  # particular core.

  class Client

    attr_reader :base_url, :rawclient

    def initialize(url)
      @base_url  = url.chomp('/')
      @rawclient = HTTPClient.new
    end

    # Construct a URL for the given arguments that hit the configured solr
    # @return [String] the new url, based on the base_url and the passed args
    def url(*args)
      [@base_url, *args].join('/').chomp('/')
    end

    # Call a get on the underlying http client and return the content
    def raw_get_content(path, args={})
      @rawclient.get(url(path), args).content
    end

    # A basic get to the instance (not any specific core)
    # @param [String] path The parts of the URL that comes after the core
    # @param [Hash] args The url arguments
    # @return [Hash] the parsed-out response
    def _get(path, args={})
      path.sub! /\A\//, ''
      args['wt'] = 'json'
      JSON.parse(raw_get_content(path, args))
    end

    #  post JSON data.
    # @param [String] path The parts of the URL that comes after the core
    # @param [Hash,Array] object_to_post The data to post as json
    # @return [Hash] the parsed-out response

    def _post_json(path, object_to_post)
      resp = @rawclient.post(url(path), JSON.dump(object_to_post), {'Content-type' => 'application/json'})
      JSON.parse(resp.content)
    end

    # Get from solr, and return a Response object of some sort
    def get(path, args = {}, response_type = nil)
      response_type = SimpleSolr::Response::GenericResponse if response_type.nil?
      response_type.new(_get(path, args))
    end

    # Post an object as JSON and return a Response object
    def post_json(path, object_to_post, response_type = nil)
      response_type = SimpleSolr::Response::GenericResponse if response_type.nil?
      response_type.new(_post_json(path, object_to_post))
    end


    # Get a client specific to the given core2
    def core(corename)
      SimpleSolr::Core.new(@base_url, corename)
    end

    # Get the core data for the currently installed cores
    def core_data(corename)
      cdata = get('admin/cores', {'wt' => 'json'})
      cdata.status[corename]
    end

    def cores
      cdata = get('admin/cores', {'wt' => 'json'}).status.keys
    end


    # Create a new, temporary core
    #noinspection RubyWrongHash
    def new_core(corename)
      dir      = temp_core_dir_setup(corename)

      args = {
          :wt          => 'json',
          :action      => 'CREATE',
          :name        => corename,
          :instanceDir => dir
      }

      get('admin/cores', args)
      core(corename)

    end

    def temp_core
      new_core(SecureRandom.uuid)
    end

    # Set up files for a temp core
    def temp_core_dir_setup(corename)
      dest = Dir.mktmpdir("simple_solr_#{corename}")
      src  = SAMPLE_CORE_DIR
      FileUtils.cp_r File.join(src, '.'), dest
      dest
    end

    # Unload all cores whose length is 36 characters (which we're
    # assuming is a temp_core gid)
    def unload_temp_cores
      cores.each do |k|
        core(k).unload if k.size == 36
      end
    end

  end


  # Connect to / deal with a specific core

  class Core < Client
    require 'simple_solr/client/index'
    include SimpleSolr::Core::Index
    extend Forwardable

    attr_accessor :core, :client
    alias_method :name, :core

    CORE_DATA_METHODS = [:index, :default?, :last_modified, :number_of_documents]
    SCHEMA_METHODS = [:add_field, :add_field_type]

    CORE_DATA_METHODS.each do |m|
      define_method(m) { core_data.send(m) }
    end

    SCHEMA_METHODS.each do |m|
      define_method(m) do |f|
        schema.send(m,f)
        dirty!
      end
    end




    def initialize(url, core)
      super(url)
      @core      = core
      @client    = SimpleSolr::Client.new(url)
    end

    # Mark this core as "dirty", necessitating a reload of, e.g.,
    # core data. Basically, let anything cached know it needs to be
    # re-fetched
    def dirty!
      @core_data = nil
      @schema = nil
      self
    end

    def schema
      @schema ||= SimpleSolr::Schema.new(self)
    end

    def url(*args)
      [@base_url, @core, *args].join('/').chomp('/')
    end

    # Send JSON to this core's update/json handler
    def update(object_to_post, response_type = nil)
      post_json('update/json', object_to_post, response_type)
    end


    # Get the core data for this core
    def core_data
      @core_data ||= CoreData.new @client.core_data(core)
    end

    # Reload this core, reading in the schema, solrconifg, etc. again
    def reload
      update({:commit => {}})
      dirty!
      self
    end

    # Unload the current core and delete all its files
    # @return The (non-core-specific) SimpleSolr::Client
    def unload
      @client.get('admin/cores', {:wt => 'json', :core => core, :action => 'UNLOAD', :deleteInstanceDir => true})
      dirty!
      @client
    end



  end


end
