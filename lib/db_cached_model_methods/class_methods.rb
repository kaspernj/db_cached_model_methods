module DbCachedModelMethods::ClassMethods
  def create_cached_methods_table!
    migration_table_creator = DbCachedModelMethods::MigrationTableCreator.new(model: self)
    migration_table_creator.migrate(:up)
  end

  def drop_cached_methods_table!
    migration_table_creator = DbCachedModelMethods::MigrationTableCreator.new(model: self)
    migration_table_creator.migrate(:down)
  end

  def db_cached_model_methods
    @@__db_cached_model_methods ||= {methods: {}}
  end

  def db_cached_model_method(method_name)
    db_cached_model_methods.fetch(:methods).fetch(method_name)
  end

  def db_cached_model_methods_update!(args = {})
    db_cached_model_methods.fetch(:methods).each do |method_name, cache_args|
      next if cache_args.fetch(:require_args)
      puts "Updating: #{method_name}" if args[:progress_bar]
      DbCachedModelMethods::CacheBuilder.new(model_class: self, method: method_name, progress_bar: args[:progress_bar]).execute
    end
  end

  def cache_method_in_db(args = {})
    method_name = args.fetch(:method).to_sym
    raise "'#{method_name}' does not exist. Have you put \"cache_method_in_db\" below the method definition?" unless instance_methods.include?(method_name)
    raise "'#{method_name}' has already been cached" if db_cached_model_methods.fetch(:methods).key?(method_name)

    expires_in = args[:expires_in].presence || 1.hour
    persist = args[:persist] || false
    require_args = false

    if args.key?(:require_args)
      require_args = args.fetch(:require_args)
    else
      arity = instance_method(method_name).arity
      require_args = true if arity > 0 || arity < -1
    end

    cache_args = args.merge(
      persist: persist,
      require_args: require_args,
      expires_in: expires_in
    )
    db_cached_model_methods.fetch(:methods)[method_name] = cache_args

    DbCachedModelMethods::ModelManipulator.new(model_class: self, method_name: method_name, cache_args: cache_args).execute
  end
end
