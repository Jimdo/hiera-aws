# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hiera/backend/aws/version"

Gem::Specification.new do |spec|
  spec.name          = "hiera-aws"
  spec.version       = Hiera::Backend::Aws::VERSION
  spec.authors       = ["Mathias Lafeldt", "Deniz Adrian", "Soenke Ruempler"]
  spec.email         = ["mathias.lafeldt@jimdo.com", "deniz.adrian@jimdo.com", "soenke.ruempler@jimdo.com"]
  spec.description   = %q{Hiera AWS Backend}
  spec.summary       = %q{Hiera AWS Backend}
  spec.homepage      = "https://github.com/Jimdo/hiera-aws"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop", "~> 0.21.0"
  spec.add_development_dependency "webmock"
end
