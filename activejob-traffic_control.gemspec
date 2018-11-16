# frozen_string_literal: true
# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_job/traffic_control/version"

Gem::Specification.new do |spec|
  spec.name          = "activejob-traffic_control"
  spec.version       = ActiveJob::TrafficControl::VERSION
  spec.authors       = ["Nick Elser"]
  spec.email         = ["nick.elser@gmail.com"]

  spec.summary       = %q(Traffic control for ActiveJob)
  spec.description   = %q(Traffic control for ActiveJob: Concurrency/enabling/throttling)
  spec.homepage      = "https://www.activejobtrafficcontrol.com"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 4.2"
  spec.add_dependency "activesupport", ">= 4.2"
  spec.add_dependency "suo"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4.7"
  spec.add_development_dependency "connection_pool"
  spec.add_development_dependency "redis-namespace", "~> 1.6"
end
