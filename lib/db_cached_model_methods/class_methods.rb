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

  def db_cached_model_methods_update!(args = {})
    db_cached_model_methods.fetch(:methods).each do |method_name, cache_args|
      next if cache_args.fetch(:require_args)
      puts "Updating: #{method_name}" if args[:progress_bar]
      DbCachedModelMethods::CacheBuilder.new(model_class: self, method: method_name, progress_bar: args[:progress_bar]).execute
    end
  end

  def cache_method_in_db(args = {})
    method_name = args.fetch(:method)

    cached_method_name = "cached_#{method_name}"

    expires_in = args[:expires_in].presence || 1.hour

    if args.key?(:require_args)
      require_args = args.fetch(:require_args)
    else
      require_args = true
    end

    db_cached_model_methods[:methods][method_name] = {type: args.fetch(:type), require_args: require_args, expires_in: expires_in}

    __send__(:define_method, cached_method_name) do |*method_args, &method_blk|
      DbCachedModelMethods::CachedCall.new(
        args: method_args,
        block: method_blk,
        method_name: method_name,
        model: self
      ).call
    end
  end
end
