module SimpleSolr

  ESCAPE_CHARS = '+-&|!(){}[]^"~*?:\\'
  ESCAPE_MAP   = ESCAPE_CHARS.split(//).each_with_object({}) {|x,h| h[x] = "\\" + x}
  ESCAPE_PAT   = Regexp.new('[' + Regexp.quote(ESCAPE_CHARS) + ']')

  # Escape those characters that need escaping to be valid lucene syntax.
  # Is *not* called internally, since how as I supposed to know if the parens/quotes are a
  # part of your string or there for legal lucene grouping?
  #
  def self.escape(str)
    esc = str.to_s.gsub(ESCAPE_PAT, ESCAPE_MAP)
  end


  # Where is the sample core configuration?
  SAMPLE_CORE_DIR = File.absolute_path File.join(File.dirname(__FILE__), '..', 'solr_sample_core')

end

require 'httpclient'
require 'forwardable'

# Choose a JSON-compatible json parser/producer
if defined? JRUBY_VERSION
  require 'json'
else
  require 'oj'
  Oj.mimic_JSON
end




require "simple_solr/version"
require 'simple_solr/client'

