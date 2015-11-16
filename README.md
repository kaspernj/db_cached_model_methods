# DbCachedModelMethods

## Install

Add to your Gemfile and bundle:
```ruby
gem "db_cached_model_methods"
```

Add a migration to create the extra tables in your database:
```ruby
class CreateUsersCache < ActiveRecord::Migration
  def up
    User.create_cached_methods_table!
  end

  def down
    User.drop_cached_methods_table!
  end
end
```

## Usage

Include in your model and specify which methods to add cache versions for:

```ruby
class User < ActiveRecord::Base
  include DbCachedModelMethods

  cache_method_in_db method: :heavy_method, type: :integer

  def heavy_method
    ...
  end
end
```

Both the "method" and "type" argument are required. You can also give the following:

- "persist" - will try to always keep a cached value in the database, so you can use it in various queries with joins without leaving anyone out. It will update the cache instead of deleting it when cleaning, so your updates will be slower!
- "override" & "override_uncached" - will override the original method with the one of the cached versions. Uncached will always call the original method and attempt but also update the cache if necessary.
- "expires_in" - how long until the cache should expire. Can be a time like `1.hour` or a proc which will do a callback with the model and expect a time-duration to be returned. The default is one hour.

To call the cached version you need to append "cached_" to the method name. Checks if a cached version exist, and if it isn't expired, it will return that value. It creates the cache if it doesn't exist or update the existing cache, if it is expired.
```ruby
user.cached_heavy_method
```

Forces a call to the original method, updates the cache and returns the value:
```ruby
user.uncached_heavy_method
```

Always just calls the original method - even if it is overriden. It won't create, update or touch the cache the cache.
```ruby
user.original_heavy_method
```

You can access the cache-objects through the added "db_caches" relationship:
```ruby
user.db_caches.where(method_name: "...")
```

You probably want to generate cache for a model right away:
```ruby
User.db_cached_model_methods_update!
```

If you have "progress_bar" bundled:
```ruby
User.db_cached_model_methods_update!(progress_bar: true)
```

You can also update the cache for each method:
```ruby
DbCachedModelMethods::CacheBuilder.new(model_class: User, method: :heavy_method, progress_bar: true).execute
```

# Licence

This project rocks and uses MIT-LICENSE.
