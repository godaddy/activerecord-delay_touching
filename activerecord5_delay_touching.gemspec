# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord/delay_touching/version'

Gem::Specification.new do |spec|
  spec.name          = "activerecord5_delay_touching"
  spec.version       = Activerecord::DelayTouching::VERSION
  spec.authors       = ["GoDaddy P&C Commerce", "Brian Morearty"]
  spec.email         = ["nemo-engg@godaddy.com", "brian@morearty.org"]
  spec.summary       = %q{Batch up your ActiveRecord "touch" operations for better performance.}
  spec.description   = %q{Batch up your ActiveRecord "touch" operations for better performance. ActiveRecord::Base.delay_touching do ... end. When "end" is reached, all accumulated "touch" calls will be consolidated into as few database round trips as possible.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency             "activerecord", ">= 4.2", "< 5.3"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "rspec-rails", "~> 3.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-rcov"
  spec.add_development_dependency "yarjuf"
end
