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
    @__db_cached_model_methods ||= {methods: {}}
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

    nil
  end

  def cache_method_in_db(args = {})
    DbCachedModelMethods::ModelManipulator.new(
      args: args,
      model_class: self
    ).execute
  end
end
