# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timerage/version'

Gem::Specification.new do |spec|
  spec.name          = "timerage"
  spec.version       = Timerage::VERSION
  spec.authors       = ["Peter Williams", "Chris Schneider"]
  spec.email         = ["cschneider@comverge.com"]
  spec.summary       = %q{Simple refinement to Range to allow Time or Date as arguments}
  spec.description   = %q{Simple refinement to Range to allow Time or Date as arguments}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ["> 3.0.0.a", "< 4"]
  spec.add_development_dependency "activesupport"
end
