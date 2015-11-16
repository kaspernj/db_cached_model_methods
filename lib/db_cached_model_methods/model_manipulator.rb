class DbCachedModelMethods::ModelManipulator
  ALLOWED_ARGS = [:expires_in, :method, :override, :override_uncached, :persist, :require_args, :type]

  def initialize(args)
    @args = args.fetch(:args)
    @model_class = args.fetch(:model_class)
    @method_name = @args.fetch(:method).to_sym

    @cached_method_name = "cached_#{@method_name}"
    @uncached_method_name = "uncached_#{@method_name}"
    @original_method_name = "original_#{@method_name}"

    @cache_class_name = "#{@model_class.name}Cache"
    @cache_table_name = "#{@model_class.name.underscore}_caches"

    parse_args
  end

  def execute
    define_cached_method
    define_uncached_method
    define_original_method
    define_has_one_relation if @arity == 0

    if @cache_args[:override]
      override_with_cached
    elsif @cache_args[:override_uncached]
      override_with_uncached
    end

    create_cache_on_create if @cache_args.fetch(:persist)
  end

private

  def parse_args
    unless @model_class.instance_methods.include?(@method_name)
      raise "'#{@method_name}' does not exist. Have you put \"cache_method_in_db\" below the method definition?"
    end

    raise "'#{@method_name}' has already been cached" if @model_class.db_cached_model_methods.fetch(:methods).key?(@method_name)

    @args.each_key do |key|
      raise "Illegal argument: #{key}" unless ALLOWED_ARGS.include?(key)
    end

    @arity = @model_class.instance_method(@method_name).arity

    create_cache_args
  end

  def create_cache_args
    expires_in = @args[:expires_in].presence || 1.hour
    persist = @args[:persist] || false
    require_args = false

    if @args.key?(:require_args)
      require_args = @args.fetch(:require_args)
    else
      require_args = true if @arity > 0 || @arity < -1
    end

    @cache_args = @args.merge(
      persist: persist,
      require_args: require_args,
      expires_in: expires_in
    )
    @model_class.db_cached_model_methods.fetch(:methods)[@method_name] = @cache_args
  end

  def define_cached_method
    method_name = @method_name

    @model_class.__send__(:define_method, @cached_method_name) do |*method_args, &method_blk|
      DbCachedModelMethods::CachedCall.new(
        args: method_args,
        block: method_blk,
        method_name: method_name,
        model: self
      ).call
    end
  end

  def define_uncached_method
    method_name = @method_name

    @model_class.__send__(:define_method, @uncached_method_name) do |*method_args, &method_blk|
      DbCachedModelMethods::CachedCall.new(
        args: method_args,
        block: method_blk,
        method_name: method_name,
        model: self,
        force: true
      ).call
    end
  end

  def define_original_method
    @model_class.__send__(:alias_method, "original_#{@method_name}", @method_name)
  end

  def define_has_one_relation
    relation_name = "db_cache_#{@method_name}".to_sym
    method_name = @method_name
    unique_key = DbCachedModelMethods::CacheKeyCalculator.for_args([])

    where_proc = -> { where(method_name: method_name, unique_key: unique_key) }

    @model_class.has_one relation_name, where_proc, class_name: @cache_class_name, foreign_key: "resource_id"
  end

  def override_with_uncached
    remove_original_method
    uncached_method_name = @uncached_method_name

    @model_class.__send__(:define_method, @method_name) do
      __send__(uncached_method_name)
    end
  end

  def override_with_cached
    remove_original_method
    cached_method_name = @cached_method_name

    @model_class.__send__(:define_method, @method_name) do
      __send__(cached_method_name)
    end
  end

  def create_cache_on_create
    cached_method_name = @cached_method_name

    @model_class.__send__(:after_create) do |model|
      model.__send__(cached_method_name)
    end
  end

private

  def remove_original_method
    @model_class.__send__(:remove_method, @method_name)
  end
end
