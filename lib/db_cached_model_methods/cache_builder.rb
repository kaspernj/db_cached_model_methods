require "active-record-transactioner"

class DbCachedModelMethods::CacheBuilder
  def initialize(args)
    @model_class = args.fetch(:model_class)
    @method = args.fetch(:method)
    @progress_bar = args[:progress_bar]
  end

  def execute
    progress_bar = ProgressBar.new(@model_class.count) if @progress_bar

    ActiveRecordTransactioner.new do |transactioner|
      @model_class.includes(:db_caches).find_each do |model|
        DbCachedModelMethods::CachedCall.new(
          args: [],
          block: nil,
          method_name: @method,
          model: model,
          transactioner: transactioner
        ).call

        progress_bar.increment! if progress_bar
      end
    end
  end
end
