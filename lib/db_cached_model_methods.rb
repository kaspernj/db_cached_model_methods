module DbCachedModelMethods
  extend ActiveSupport::Autoload

  autoload :CacheKeyCalculator
  autoload :ClassMethods
  autoload :InstanceMethods
  autoload :Compatibility
  autoload :MigrationTableCreator

  def self.included(base)
    base.extend DbCachedModelMethods::ClassMethods
    base.include DbCachedModelMethods::InstanceMethods

    table_name = "#{base.name.underscore}_caches"
    class_name = "#{base.name}Cache"
    parent_relation_name = base.name.underscore.to_sym

    clazz = Class.new(ActiveRecord::Base) do
      if respond_to?(:set_table_name)
        set_table_name(table_name)
      else
        self.table_name = table_name
      end

      belongs_to parent_relation_name, foreign_key: :resource_id
      validates parent_relation_name, :expires_at, presence: true

      def expired?
        !expires_at? || expires_at < Time.zone.now
      end
    end

    Object.const_set(class_name, clazz)

    base.class_eval do
      has_many :db_caches, class_name: class_name, foreign_key: :resource_id, dependent: :destroy
    end
  end
end
