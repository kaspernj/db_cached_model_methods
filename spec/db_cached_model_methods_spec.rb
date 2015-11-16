require "spec_helper"

describe DbCachedModelMethods do
  let!(:user) { create :user }

  it "#cache_method_in_db" do
    expect(user.some_method_called).to eq 0
    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.for("some_method").count).to eq 1
    expect(user.some_method_called).to eq 1

    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.for("some_method").count).to eq 1
    expect(user.some_method_called).to eq 1
  end

  it "cleans up when deleting parent model" do
    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.for("some_method").count).to eq 1
    user.destroy!
    expect(user.db_caches.for("some_method").count).to eq 0
  end

  it "overrides original methods when told to" do
    expect(user.db_caches.for("overridden_method").count).to eq 0
    expect(user.overridden_method).to eq 7
  end
end
