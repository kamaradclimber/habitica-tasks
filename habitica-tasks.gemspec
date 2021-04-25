require_relative 'lib/habitica/tasks/version'

Gem::Specification.new do |spec|
  spec.name          = "habitica-tasks"
  spec.version       = Habitica::Tasks::VERSION
  spec.authors       = ["Grégoire Seux"]
  spec.email         = ["grego_habiticatasks@familleseux.net"]

  spec.summary       = %q{A gem to manage common patterns on habitica}
  spec.description   = %q{A gem to manage common patterns on habitica}
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
