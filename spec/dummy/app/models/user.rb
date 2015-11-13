class User < ActiveRecord::Base
  attr_accessor :some_method_called

  include DbCachedModelMethods

  cache_method_in_db method: :some_method, type: :integer

  def some_method
    @some_method_called ||= 0
    @some_method_called += 1

    5
  end
end
