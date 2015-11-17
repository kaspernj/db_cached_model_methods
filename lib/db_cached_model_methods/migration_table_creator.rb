class DbCachedModelMethods::MigrationTableCreator
  def initialize(args)
    @model = args.fetch(:model)
  end

  def migrate(direction)
    spawn_migration_class.migrate(direction)
  end

private

  def spawn_migration_class
    migration_class = create_class

    migration_class.table_name = "#{@model.name.underscore}_caches"
    migration_class.column_name = "#{@model.name.underscore}_id".to_sym
    migration_class
  end

  def create_class
    Class.new(ActiveRecord::Migration) do
      class << self
        attr_accessor :column_name, :table_name
      end

      def up
        create_table self.class.table_name do |t|
          t.integer :resource_id
          t.string :method_name
          t.string :unique_key
          t.string :string_value
          t.integer :integer_value
          t.float :float_value
          t.datetime :time_value
          t.datetime :expires_at
          t.boolean :expired
          t.timestamps
        end

        add_indexes
      end

      def down
        drop_table self.class
      end

      def add_indexes
        add_index self.class.table_name, :resource_id
        add_index self.class.table_name, [:resource_id, :method_name, :unique_key], unique: true, name: "#{self.class.table_name}_unique_resource_method_key"
        add_index self.class.table_name, :string_value
        add_index self.class.table_name, :integer_value
        add_index self.class.table_name, :float_value
        add_index self.class.table_name, :time_value
        add_index self.class.table_name, :expires_at
        add_index self.class.table_name, :expired
      end
    end
  end
end
