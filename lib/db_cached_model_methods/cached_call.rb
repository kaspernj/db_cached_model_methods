class DbCachedModelMethods::CachedCall
  def self.through_slave_db
    @octopus ||= DbCachedModelMethods::CacheConfig.current.octopus

    if @octopus
      Octopus.using(@octopus) do
        yield
      end
    else
      yield
    end
  end

  def initialize(args)
    @args = args.fetch(:args)
    @block = args.fetch(:block)
    @method_name = args.fetch(:method_name)
    @model = args.fetch(:model)
    @method_data = @model.class.db_cached_model_methods.fetch(:methods).fetch(@method_name)
    @expires_in = @method_data.fetch(:expires_in)
    @transactioner = args[:transactioner]
    @force = args[:force]
  end

  def call
    result_type = @method_data.fetch(:type)

    find_cache
    regenrate_cache! if regenerate_cache?

    @cache.__send__("#{result_type}_value")
  end

private

  def regenerate_cache?
    return true if @force || !@cache
    @cache.expired_by_date_or_boolean?
  end

  def regenrate_cache!
    @cache ||= @model.db_caches.new
    result_type = @method_data.fetch(:type)

    call_result = call_method

    if @expires_in.is_a?(Proc)
      expires_at = @expires_in.call(@model, @cache)
    else
      expires_at = @expires_in.from_now
    end

    expires_at ||= 1.hour.from_now
    result_attr = "#{result_type}_value".to_sym

    new_cache_data = {
      expires_at: expires_at,
      expired: nil,
      method_name: @method_name,
      unique_key: cache_key,
      result_attr => call_result
    }

    save_cache(new_cache_data)
  end

  def save_cache(new_cache_data)
    @cache.assign_attributes(new_cache_data)

    if @transactioner
      @transactioner.save! @cache if @cache.changed?
    else
      begin
        @cache.save!
      # rubocop:disable Lint/HandleExceptions
      rescue ActiveRecord::RecordNotUnique
        # rubocop:enable Lint/HandleExceptions
        # Ignore - cache must have been inserted in between an autoload and this call
      end
    end
  end

  def cache_key
    @cache_key ||= DbCachedModelMethods::CacheKeyCalculator.for_args(@args)
  end

  def call_method
    return call_original_through_octopus if @method_data[:with_slave_db]
    call_original_method
  end

  def call_original_method
    @model.__send__("original_#{@method_name}", *@args, &@block)
  end

  def call_original_through_octopus
    DbCachedModelMethods::CachedCall.through_slave_db do
      call_original_method
    end
  end

  def find_cache
    has_one_relation_name = "db_cache_#{@method_name}".to_sym

    if @model.db_caches.loaded?
      @cache = find_cache_by_autoload
    elsif @model.association(has_one_relation_name).loaded?
      @cache = find_cache_by_association_autoload(has_one_relation_name)
    else
      @cache = find_cache_by_query
    end
  end

  def find_cache_by_query
    DbCachedModelMethods::CachedCall.through_slave_db do
      @model.db_caches.find_by(method_name: @method_name, unique_key: cache_key)
    end
  end

  def find_cache_by_autoload
    @model.db_caches.to_a.detect { |db_cache| db_cache.method_name == @method_name.to_s && db_cache.unique_key == cache_key }
  end

  def find_cache_by_association_autoload(has_one_relation_name)
    @model.__send__(has_one_relation_name)
  end
end
