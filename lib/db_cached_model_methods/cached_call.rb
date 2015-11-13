class DbCachedModelMethods::CachedCall
  def initialize(args)
    @args = args.fetch(:args)
    @block = args.fetch(:block)
    @method_name = args.fetch(:method_name)
    @model = args.fetch(:model)
    @method_data = @model.class.db_cached_model_methods.fetch(:methods).fetch(@method_name)
    @transactioner = args[:transactioner]
    @octopus = DbCachedModelMethods::CacheConfig.current.octopus
  end

  def call
    result_type = @method_data.fetch(:type)
    result_attr = "#{result_type}_value".to_sym

    find_cache

    if !@cache || @cache.expired?
      @cache ||= @model.db_caches.new

      call_result = @model.__send__(@method_name, *@args, &@block)

      @cache.assign_attributes(
        expires_at: @method_data.fetch(:expires_in).from_now,
        method_name: @method_name,
        unique_key: cache_key,
        result_attr => call_result
      )

      if @transactioner
        @transactioner.save! @cache
      else
        @cache.save!
      end
    end

    @cache.__send__("#{result_type}_value")
  end

private

  def cache_key
    @cache_key ||= DbCachedModelMethods::CacheKeyCalculator.new(args: @args).calculate
  end

  def find_cache
    if @model.db_caches.loaded?
      @cache = find_cache_by_autoload
    else
      @cache = find_cache_by_query
    end
  end

  def find_cache_by_query
    if @octopus
      Octopus.using(@octopus) do
        @model.db_caches.find_by(method_name: @method_name, unique_key: cache_key)
      end
    else
      @model.db_caches.find_by(method_name: @method_name, unique_key: cache_key)
    end
  end

  def find_cache_by_autoload
    result = @model.db_caches.to_a.detect { |db_cache| db_cache.method_name == @method_name.to_s && db_cache.unique_key == cache_key }
  end
end
