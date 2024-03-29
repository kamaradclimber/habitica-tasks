# frozen_string_literal: true

require_relative 'lib/habitica/tasks/version'

Gem::Specification.new do |spec|
  spec.name          = 'habitica-tasks'
  spec.version       = Habitica::Tasks::VERSION
  spec.authors       = ['Grégoire Seux']
  spec.email         = ['grego_habiticatasks@familleseux.net']

  spec.summary       = 'A gem to manage common patterns on habitica'
  spec.description   = 'A gem to manage common patterns on habitica'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.homepage = 'https://github.com/kamaradclimber/habitica-tasks'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'habitica_client'
  spec.add_runtime_dependency 'jira-ruby'
  spec.add_runtime_dependency 'rufus-scheduler'
  spec.add_runtime_dependency 'sinatra'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rubocop'
end
