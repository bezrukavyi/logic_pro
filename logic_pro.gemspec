require_relative 'lib/logic_pro/version'

Gem::Specification.new do |spec|
  spec.name          = 'logic_pro'
  spec.version       = LogicPro::VERSION
  spec.authors       = ['bezrukavyi']
  spec.email         = ['yaroslav.bezrukavyi@gmail.com']

  spec.summary       = 'Logic Pro'
  spec.description   = 'Interactor + Form Object + ActiveModel::Validation'
  spec.homepage      = 'https://github.com/bezrukavyi/logic_pro'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.add_dependency 'activemodel'
  spec.add_dependency 'dry-struct'
  spec.add_dependency 'interactor'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
