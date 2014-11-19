module SimpleSolr
  class CoreData

    attr_reader :raw_solr_hash

    def initialize(solr_response_core_hash)
      @raw_solr_hash = solr_response_core_hash
    end

    def index
      @raw_solr_hash['index']
    end

    def default?
      @raw_solr_hash['isDefaultCore']
    end

    def last_modified
      Time.parse index['lastModified']
    end

    def number_of_documents
      index['numDocs']
    end

    def data_dir
      @raw_solr_hash['dataDir']
    end

    def instance_dir
      @raw_solr_hash['instanceDir']
    end

    def config_file
      File.join(instance_dir, 'conf', @raw_solr_hash['config'])
    end

    def schema_file
      File.join(instance_dir, 'conf', @raw_solr_hash['schema'])
    end

  end
end
