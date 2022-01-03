Gem::Specification.new do |s|
  s.name = %q{world_factory}
  s.version = "0.1.2"
  s.date = %q{2021-01-03}
  s.author = "FutureProof Retail"
  s.summary = %q{Simple gem for generating "Worlds" of interrelated models, for testing and production}
  s.files = [
    "lib/world_factory.rb"
  ]
  s.homepage = "https://www.futureproofretail.com"
  s.license = "MIT"
  s.require_paths = ["lib"]
  s.add_dependency "activesupport", ">= 5.0"
end
