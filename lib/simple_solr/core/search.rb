require 'simple_solr/response/query_response'

module SimpleSolr::Core::Search

  def fv_search(field, value)
    v = value
    v = SimpleSolr.lucene_escape Array(value).join(' ') unless v == '*'
    kv = "#{field}:#{v}"
    get('select', {:q => kv}, SimpleSolr::Response::QueryResponse)
  end

  def all
    fv_search('*', '*')
  end

  def id(i)
    fv_search('id', i).first
  end


end
