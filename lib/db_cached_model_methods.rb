module DbCachedModelMethods
  extend ActiveSupport::Autoload

  CLASSES_WITH_DB_CACHE = {}

  autoload :CacheBuilder
  autoload :CacheConfig
  autoload :CacheCleaner
  autoload :CachedCall
  autoload :CacheKeyCalculator
  autoload :ClassMethods
  autoload :GeneralCacheCleaner
  autoload :InstanceMethods
  autoload :ModelManipulator
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

      belongs_to :resource, class_name: base.name
      belongs_to parent_relation_name, foreign_key: :resource_id
      validates parent_relation_name, :expires_at, presence: true

      scope :for, lambda { |method_name, *args|
        if args.any?
          unique_key = DbCachedModelMethods::CacheKeyCalculator.for_args(args)
          where(method_name: method_name, unique_key: unique_key)
        else
          where(method_name: method_name).with_no_args
        end
      }

      scope :with_no_args, -> { where(unique_key: "0") }
      scope :expired, -> { where("#{table_name}.expired = 1 OR #{table_name}.expires_at < ?", Time.zone.now) }
      scope :expire!, -> { update_all(expired: 1) }

      def expired_by_date_or_boolean?
        expired? || expires_at < Time.zone.now
      end
    end

    Object.const_set(class_name, clazz)

    base.class_eval do
      has_many :db_caches, class_name: class_name, foreign_key: :resource_id, dependent: :destroy
    end

    CLASSES_WITH_DB_CACHE[base] = {
      table_name: table_name,
      class_name: class_name,
      constant: clazz
    }
  end
end
