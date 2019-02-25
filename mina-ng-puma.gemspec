# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mina/puma/version'

Gem::Specification.new do |spec|
  spec.name          = 'mina-ng-puma'
  spec.version       = Mina::Puma::VERSION
  spec.authors       = ['windy']
  spec.email         = ['lyfi2003@gmail.com']
  spec.description   = %q{Next Generation Puma tasks for Mina}
  spec.summary       = %q{Next Generation Puma tasks for Mina}
  spec.homepage      = 'https://github.com/windy/mina-ng-puma'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'mina', '~> 1.2.0'
  spec.add_dependency 'puma', '>= 2.13'

  spec.add_development_dependency 'bundler', '>= 1.3'
  spec.add_development_dependency 'rake'
end
