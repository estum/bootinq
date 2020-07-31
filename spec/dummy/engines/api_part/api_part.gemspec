# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = "api_part"
  s.version     = "0.0.1"
  s.authors     = ["John Doe"]
  s.email       = ["john.doe@example.com"]
  s.summary     = "ApiPart"
  s.description = "ApiPart"
  s.homepage    = "http://example.com"
  s.license     = "MIT"
  s.files       = Dir['lib/**/*.rb']
end