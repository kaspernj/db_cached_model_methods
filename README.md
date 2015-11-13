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

To call the cached version you need to append "cached_" to the method name:
```ruby
user.cached_heavy_method
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
