class DbCachedModelMethods::GeneralCacheCleaner
  def initialize(args = {})
    @progress_bar = args[:progress_bar]
  end

  def delete_expired
    DbCachedModelMethods::CLASSES_WITH_DB_CACHE.each do |model_class, model_cache_data|
      methods_to_delete = []

      model_class.db_cached_model_methods.fetch(:methods).each do |method_name, cache_data|
        next if cache_data.fetch(:persist)
        methods_to_delete << method_name
      end

      model_cache_data.fetch(:constant)
        .where(method_name: methods_to_delete)
        .expired
        .delete_all
    end
  end

  def update_persisted_expired
    DbCachedModelMethods::CLASSES_WITH_DB_CACHE.each do |model_class, model_cache_data|
      methods_to_update = []

      model_class.db_cached_model_methods.fetch(:methods).each do |method_name, cache_data|
        next unless cache_data.fetch(:persist)
        methods_to_update << method_name
      end

      expired_caches = model_cache_data.fetch(:constant)
        .where(method_name: methods_to_update)
        .with_no_args
        .expired

      update_expired_caches(expired_caches)
    end
  end

private

  def update_expired_caches(expired_caches)
    progress_bar = ProgressBar.new(expired_caches.count) if @progress_bar

    expired_caches.includes(:resource).find_each do |expired_cache|
      method_to_call = "cached_#{expired_cache.method_name}"
      expired_cache.resource.__send__(method_to_call)

      progress_bar.increment! if progress_bar
    end
  end
end
