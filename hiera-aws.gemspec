# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hiera/aws/version'

Gem::Specification.new do |spec|
  spec.name          = "hiera-aws"
  spec.version       = Hiera::Aws::VERSION
  spec.authors       = ["Mathias Lafeldt", "Deniz Adrian"]
  spec.email         = ["mathias.lafeldt@jimdo.com", "deniz.adrian@jimdo.com"]
  spec.description   = %q{Hiera AWS Backend}
  spec.summary       = %q{Hiera AWS Backend}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
