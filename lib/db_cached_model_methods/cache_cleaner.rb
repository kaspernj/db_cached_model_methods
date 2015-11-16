class DbCachedModelMethods::CacheCleaner
  def initialize(args)
    @model = args.fetch(:model)
    @all_deletes = []
    @args_deletes = []
    @cache_update_calls = []
  end

  def reset_methods(method_array)
    method_array.each do |method_data|
      method_data = {method: method_data} if method_data.is_a?(Symbol)
      scan_method_data(method_data)
    end

    delete_cache
    update_cache

    nil
  end

private

  def scan_method_data(method_data)
    method_name = method_data.fetch(:method)
    persist = persist_method?(method_name)

    if method_data.key?(:args)
      unique_key = DbCachedModelMethods::CacheKeyCalculator(method_data.fetch(:args))

      if persist
        @cache_update_calls << {
          method_name: method_name,
          args: method_data.fetch(:args)
        }
      else
        @args_deletes << {
          method_name: method_name,
          unique_key: unique_key
        }
      end
    else
      if persist
        @cache_update_calls << {method_name: method_name, args: []}
      else
        @all_deletes << method_name
      end
    end
  end

  def persist_method?(method_name)
    @model.class.db_cached_model_methods.fetch(:methods).fetch(method_name)[:persist]
  end

  def delete_cache
    @model.db_caches.for(@all_deletes).delete_all if @all_deletes.any?

    return unless @args_deletes.any?

    @model.db_caches.transaction do
      @args_deletes.each do |arg_reset|
        @model.db_caches.where(arg_reset).delete
      end
    end
  end

  def update_cache
    @cache_update_calls.each do |cache_update_call|
      @model.__send__(cache_update_call.fetch(:method_name), *cache_update_call.fetch(:args))
    end
  end
end
