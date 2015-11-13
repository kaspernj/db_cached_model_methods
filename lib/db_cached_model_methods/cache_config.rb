class DbCachedModelMethods::CacheConfig
  attr_accessor :octopus

  def self.current
    @cache_config ||= new
  end
end
