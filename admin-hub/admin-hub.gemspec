$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "admin-hub/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "admin-hub"
  s.version     = AdminHub::VERSION
  s.authors     = ["Dilshod"]
  s.email       = ["tdilshod@gmail.com"]
  s.homepage    = "http://google.com/"
  s.summary     = "AdminHub."
  s.description = "AdminHub."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.1"

  #s.add_development_dependency "sqlite3"
end
