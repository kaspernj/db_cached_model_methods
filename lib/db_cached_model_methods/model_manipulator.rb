class DbCachedModelMethods::ModelManipulator
  def initialize(args)
    @model_class = args.fetch(:model_class)
    @method_name = args.fetch(:method_name)
    @cache_args = args.fetch(:cache_args)

    @cached_method_name = "cached_#{@method_name}"
    @uncached_method_name = "uncached_#{@method_name}"
    @original_method_name = "original_#{@method_name}"
  end

  def execute
    define_cached_method
    define_uncached_method
    define_original_method

    if @cache_args[:override]
      override_with_cached
    elsif @cache_args[:override_uncached]
      override_with_uncached
    end

    create_cache_on_create if @cache_args.fetch(:persist)
  end

private

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

  def override_with_uncached
    remove_original_method
    uncached_method_name = @uncached_method_name

    @model_class.__send__(:define_method, method_name) do
      @model_class.__send__(uncached_method_name)
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
