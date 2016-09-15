# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dsltasks/version'

Gem::Specification.new do |spec|
  spec.name          = "dsltasks"
  spec.version       = DSLTasks::VERSION
  spec.authors       = ["Jonathan Johnson"]
  spec.email         = ["jonjohn@byu.net"]

  spec.summary       = %q{Library and framework based on the concept of tasks for creating DSLs}
  spec.homepage      = "https://github.com/thejonjohn/dsltasks"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
