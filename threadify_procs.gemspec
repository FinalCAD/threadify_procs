# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'threadify_procs/version'

Gem::Specification.new do |spec|
  spec.name          = 'threadify_procs'
  spec.version       = ThreadifyProcs::VERSION
  spec.authors       = ["Antoine Qu'hen"]
  spec.email         = ["antoinequhen@gmail.com"]
  spec.summary       = %q{Launch an array of Procs within threads.}
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
