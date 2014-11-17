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
      index['isDefaultCore']
    end

    def last_modified
      Time.parse index['lastModified']
    end

    def number_of_documents
      index['numDocs']
    end

  end
end
