# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubygems/precompiled/version'

Gem::Specification.new do |spec|
  spec.name          = "rubygems-precompiled"
  spec.version       = Rubygems::Precompiled::VERSION
  spec.authors       = ["Thomas Haggett"]
  spec.email         = ["thomas-rubygemplugin@haggett.org"]
  spec.description   = %q{RubyGems plugin to allow a gem's compiled extension to be pre-built and cached}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/joshado/rubygems-precompiled"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "cucumber"
end
