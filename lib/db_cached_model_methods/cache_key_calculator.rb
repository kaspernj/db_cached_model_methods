class DbCachedModelMethods::CacheKeyCalculator
  attr_reader :cache_key

  def initialize(args)
    @args = args.fetch(:args)
    @parts = [@args.length]
  end

  def calculate
    @args.each do |arg|
      if arg.is_a?(ActiveRecord::Base)
        @parts << "#{arg.class.name}_#{arg.id}_#{arg.updated_at}"
      else
        @parts = arg.to_s
      end
    end

    @parts.join("-")
  end
end
