# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = "shared"
  s.version     = "0.0.1"
  s.authors     = ["Tõnis Simo"]
  s.email       = ["anton.estum@gmail.com"]
  s.summary     = "Shared"
  s.description = "Shared"
  s.homepage    = "http://localhost"
  s.license     = "MIT"
  s.files       = Dir['lib/**/*.rb']
end