# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_solr/version'

Gem::Specification.new do |spec|
  spec.name          = "simple_solr"
  spec.version       = SimpleSolr::VERSION
  spec.authors       = ["Bill Dueber"]
  spec.email         = ["bill@dueber.com"]
  spec.summary       = %q{Interact with a Solr API via JSON}
  spec.homepage      = "https://github.com/billdueber/simple_solr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  # Thread-safe, cross-platform http client
  spec.add_dependency "httpclient"

  # XML parsing. Slower, but less screwy than Nokogiri
  spec.add_dependency 'nokogiri'

  # Only require Oj for MRI/rbx. We'll use stock JSON on jruby
  if defined? JRUBY
    spec.platform = "java"
  else
    spec.add_dependency 'oj'
  end


  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency 'minitest-reporters'
end
