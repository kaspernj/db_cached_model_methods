module DbCachedModelMethods::InstanceMethods
  def reset_db_cache(method_array)
    cache_cleaner = DbCachedModelMethods::CacheCleaner.new(model: self)
    cache_cleaner.reset_methods(method_array)
  end
end
