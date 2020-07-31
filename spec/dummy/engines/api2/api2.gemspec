# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = "api2"
  s.version     = "0.0.1"
  s.authors     = ["John Doe"]
  s.email       = ["john.doe@example.com"]
  s.summary     = "Api2"
  s.description = "Api2"
  s.homepage    = "http://example.com"
  s.license     = "MIT"
  s.files       = Dir['lib/**/*.rb']
end