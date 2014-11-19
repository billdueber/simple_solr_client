module SimpleSolr::Core::Search

  def fv_search(field, value)
    v = value
    v = SimpleSolr.lucene_escape Array(value).join(' ') unless v == '*'
    kv = "#{field}:#{v}"
    get('select', {:q => kv})
  end

  def all
    fv_search('*', '*')
  end


end
