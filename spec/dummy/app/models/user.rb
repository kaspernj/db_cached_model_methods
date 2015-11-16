class User < ActiveRecord::Base
  attr_accessor :some_method_called, :persisted_method_called, :expires_in_proc_method_called
  attr_accessor :expires_in_expire, :overwritten_method_called, :overwritten_uncached_method_called

  include DbCachedModelMethods

  after_initialize :set_counts

  def some_method
    @some_method_called ||= 0
    @some_method_called += 1

    5
  end
  cache_method_in_db method: :some_method, type: :integer

  def persisted_method
    @persisted_method_called ||= 0
    @persisted_method_called += 1

    6
  end
  cache_method_in_db method: :persisted_method, type: :integer, persist: true, expires_in: 2.hours

  def overridden_method
    @overwritten_method_called ||= 0
    @overwritten_method_called += 1

    7
  end
  cache_method_in_db method: :overridden_method, type: :integer, override: true

  def overridden_uncached_method
    @overwritten_uncached_method_called ||= 0
    @overwritten_uncached_method_called += 1

    8
  end
  cache_method_in_db method: :overridden_uncached_method, type: :integer, override_uncached: true

  def expires_in_proc_method
    @expires_in_proc_method_called ||= 0
    @expires_in_proc_method_called += 1

    8
  end
  cache_method_in_db method: :expires_in_proc_method, type: :integer, expires_in: proc { |user| user.expires_in_expire }

  def method_that_requires_args(arg1)
  end
  cache_method_in_db method: :method_that_requires_args, type: :integer

private

  def set_counts
    @some_method_called ||= 0
    @persisted_method_called ||= 0
    @overwritten_method_called ||= 0
    @expires_in_proc_method_called ||= 0
    @overwritten_uncached_method_called ||= 0
  end
end
