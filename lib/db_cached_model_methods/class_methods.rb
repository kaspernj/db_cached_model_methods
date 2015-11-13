module DbCachedModelMethods::ClassMethods
  def create_cached_methods_table!
    migration_table_creator = DbCachedModelMethods::MigrationTableCreator.new(model: self)
    migration_table_creator.migrate(:up)
  end

  def drop_cached_methods_table!
    migration_table_creator = DbCachedModelMethods::MigrationTableCreator.new(model: self)
    migration_table_creator.migrate(:down)
  end

  def cache_method_in_db(args = {})
    method_name = args.fetch(:method)

    cached_method_name = "cached_#{method_name}"

    @@__db_cached_model_methods ||= {methods: {}}

    expires_in = args[:expires_in].presence || 1.hour
    @@__db_cached_model_methods[:methods][method_name] = {type: args.fetch(:type), expires_in: expires_in}

    __send__(:define_method, cached_method_name) do |*args, &blk|
      method_data = @@__db_cached_model_methods.fetch(:methods).fetch(method_name)
      result_type = method_data.fetch(:type)

      result_attr = "#{result_type}_value".to_sym
      calculator = DbCachedModelMethods::CacheKeyCalculator.new(args: args).calculate

      # Check if cache exists
      cache = db_caches.find_by(method_name: method_name, unique_key: calculator.cache_key)

      if cache && cache.expired?
        cache.destroy!
        cache = nil
      end

      if !cache || cache.expired?
        cache ||= db_caches.new

        call_result = __send__(method_name, *args, &blk)

        cache.assign_attributes(
          expires_at: method_data.fetch(:expires_in).from_now,
          method_name: method_name,
          unique_key: calculator.cache_key,
          result_attr => call_result
        )
        cache.save!
      end

      cache.__send__("#{result_type}_value")
    end
  end
end
