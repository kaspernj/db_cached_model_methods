require "spec_helper"

describe DbCachedModelMethods do
  let!(:user) { create :user }

  it "caches method results" do
    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.count).to eq 1
    expect(user.some_method_called).to eq 1

    expect(user.cached_some_method).to eq 5
    expect(user.db_caches.count).to eq 1
    expect(user.some_method_called).to eq 1
  end

  it "cleans up when deleting parent model" do
    expect(user.cached_some_method).to eq 5
    expect(UserCache.count).to eq 1
    user.destroy!
    expect(UserCache.count).to eq 0
  end
end
