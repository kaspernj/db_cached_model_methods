require "spec_helper"

describe DbCachedModelMethods::CacheCleaner do
  let!(:user) { create :user }

  it "cleans cache when given the normal long method-hash as argument" do
    expect(user.some_method_called).to eq 0
    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.for("some_method").count).to eq 1

    user.reset_db_cache([{method: :some_method}])
    expect(user.db_caches.for("some_method").count).to eq 0
  end

  it "cleans when given the simple array form" do
    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.for("some_method").count).to eq 1

    user.reset_db_cache([:some_method])
    expect(user.db_caches.for("some_method").count).to eq 0
  end

  it "persists cache when the persist argument is given" do
    expect(user.persisted_method_called).to eq 1
    expect(user.uncached_persisted_method).to eq 6
    expect(user.db_caches.for("persisted_method").count).to eq 1
    expect(user.persisted_method_called).to eq 2

    user.reset_db_cache([:persisted_method])
    expect(user.db_caches.for("persisted_method").count).to eq 1
    expect(user.persisted_method_called).to eq 3
  end
end
