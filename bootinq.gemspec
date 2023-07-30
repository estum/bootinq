# frozen_string_literal: true

require_relative 'lib/bootinq/version'

Gem::Specification.new do |spec|
  spec.name          = "bootinq"
  spec.version       = Bootinq::VERSION
  spec.authors       = ["Anton"]
  spec.email         = ["anton.estum@gmail.com"]

  spec.summary       = %q{Rails Boot Inquirer}
  spec.description   = %q{Allows to select which bundle groups to boot in the current rails process}
  spec.homepage      = "https://github.com/estum/bootinq"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "zeitwerk"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
