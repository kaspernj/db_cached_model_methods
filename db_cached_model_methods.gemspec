$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "db_cached_model_methods/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "db_cached_model_methods"
  s.version     = DbCachedModelMethods::VERSION
  s.authors     = ["kaspernj"]
  s.email       = ["k@spernj.org"]
  s.homepage    = "https://github.com/kaspernj/db_cached_model_methods"
  s.summary     = "Cache result of model methods in the database, so you are able to sort and do DB based operations with them."
  s.description = "Cache result of model methods in the database, so you are able to sort and do DB based operations with them."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 4.2.0", "< 5.0.0"
  s.add_dependency "active-record-transactioner", "~> 0.0.6"

  s.add_development_dependency "sqlite3", "1.3.11"
  s.add_development_dependency "factory_girl_rails", "4.5.0"
  s.add_development_dependency "rspec-rails", "3.4.0"
  s.add_development_dependency "forgery", "0.6.0"
  s.add_development_dependency "pry", "0.10.3"
end
