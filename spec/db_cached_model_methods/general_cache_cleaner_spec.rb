require "spec_helper"

describe DbCachedModelMethods::GeneralCacheCleaner do
  let!(:user) { create :user }
  let(:general_cache_cleaner) { DbCachedModelMethods::GeneralCacheCleaner.new }

  it "#delete_expired" do
    user.cached_some_method
    expect(user.db_caches.count).to eq 2

    user.db_caches.where(method_name: "some_method").expire!
    general_cache_cleaner.delete_expired

    expect(user.db_caches.count).to eq 1
  end

  it "#update_persisted_expired" do
    expect(user.db_caches.count).to eq 1

    caches = user.db_caches.where(method_name: "persisted_method")
    cache = caches.first
    caches.expire!
    last_updated_at = cache.updated_at
    cache.reload
    expect(cache.expired_by_date_or_boolean?).to eq true
    sleep 0.01

    general_cache_cleaner.update_persisted_expired

    expect(cache.reload.updated_at).to_not eq last_updated_at
  end
end
