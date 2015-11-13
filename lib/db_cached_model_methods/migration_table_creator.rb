class DbCachedModelMethods::MigrationTableCreator
  def initialize(args)
    @model = args.fetch(:model)
  end

  def migrate(direction)
    migration_class.migrate(direction)
  end

private

  def migration_class
    migration_class = Class.new(ActiveRecord::Migration) do
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
        end

        add_index self.class.table_name, :resource_id
        add_index self.class.table_name, [:resource_id, :method_name, :unique_key], unique: true, name: "#{self.class.table_name}_unique_resource_method_key"
        add_index self.class.table_name, :string_value
        add_index self.class.table_name, :integer_value
        add_index self.class.table_name, :float_value
        add_index self.class.table_name, :time_value
        add_index self.class.table_name, :expires_at
      end

      def down
        drop_table self.class
      end
    end

    migration_class.table_name = "#{@model.name.underscore}_caches"
    migration_class.column_name = "#{@model.name.underscore}_id".to_sym
    migration_class
  end
end
