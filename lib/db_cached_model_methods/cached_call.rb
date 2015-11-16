class DbCachedModelMethods::CachedCall
  def initialize(args)
    @args = args.fetch(:args)
    @block = args.fetch(:block)
    @method_name = args.fetch(:method_name)
    @model = args.fetch(:model)
    @method_data = @model.class.db_cached_model_methods.fetch(:methods).fetch(@method_name)
    @expires_in = @method_data.fetch(:expires_in)
    @transactioner = args[:transactioner]
    @force = args[:force]
    @octopus = DbCachedModelMethods::CacheConfig.current.octopus
  end

  def call
    result_type = @method_data.fetch(:type)
    result_attr = "#{result_type}_value".to_sym

    find_cache

    if regenerate_cache?
      @cache ||= @model.db_caches.new

      call_result = @model.__send__("original_#{@method_name}", *@args, &@block)

      if @expires_in.is_a?(Proc)
        expires_at = @expires_in.call(@model, @cache)
      else
        expires_at = @expires_in.from_now
      end

      expires_at ||= 1.hour.from_now

      @cache.assign_attributes(
        expires_at: expires_at,
        method_name: @method_name,
        unique_key: cache_key,
        result_attr => call_result
      )

      if @transactioner
        @transactioner.save! @cache if @cache.changed?
      else
        @cache.save!
      end
    end

    @cache.__send__("#{result_type}_value")
  end

private

  def regenerate_cache?
    return true if @force || !@cache
    @cache.expired?
  end

  def cache_key
    @cache_key ||= DbCachedModelMethods::CacheKeyCalculator.for_args(@args)
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
    @model.db_caches.to_a.detect { |db_cache| db_cache.method_name == @method_name.to_s && db_cache.unique_key == cache_key }
  end
end
