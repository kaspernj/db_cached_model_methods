[![Build Status](https://img.shields.io/shippable/5649b1491895ca4474239301.svg)](https://app.shippable.com/projects/5649b1491895ca4474239301/builds/latest)

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

  def heavy_method
    ...
  end
  cache_method_in_db method: :heavy_method, type: :integer
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

### Autoloading / eager loading cached methods

If you want to call a cached-method in a lot of records, it makes a lot of sense to optimize the query instead of doing n+1.

You can either autoload all cached methods or the individual ones.

This autoloads all method caches including "my_method"
```ruby
User.includes(:db_caches).each do |user|
  user.my_method # Doesn't do an extra query
  user.other_method # Doesn't do an query
end
```

This autoloads only the cache for the method "my_method"
```ruby
User.includes(:db_cache_my_method).each do |user|
  user.my_method # Doesn't do an extra query
  user.other_method # Does an extra query and IMPACTS PERFORMANCE!
end
```

### Joining in a query

It is possible to join the caches through the "db_caches" and "db_cache_[method_name]" relations. If you do so, it is probably a good idea to use the `persist: true` to the `cache_method_in_db`-call.

If you don't, it is possible that the cache for most records doesn't exist. The cleaner will simply delete expired caches. If it is persisted, the cleaner will update the existing cache instead of deleting them.

```ruby
class User < ActiveRecord::Base
  include DbCachedModelMethods

  def heavy_method
    ...
  end
  cache_method_in_db method: :heavy_method, type: :integer, persist: true
end
```

You then want to create cache for all records like this:
```ruby
User.db_cached_model_methods_update!
```

If you have a big table, you can use the "progress_bar"-gem to manage your nerves:
```ruby
User.db_cached_model_methods_update!(progress_bar: true)
```


# Licence

This project rocks and uses MIT-LICENSE.
