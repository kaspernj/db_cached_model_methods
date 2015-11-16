require "spec_helper"

describe DbCachedModelMethods::ModelManipulator do
  let!(:user) { create :user }

  describe "#define_has_one_relation" do
    it "returns the correct result" do
      expect(user.respond_to?(:db_cache_persisted_method)).to eq true
      expect(user.db_cache_persisted_method).to be_a UserCache
    end

    it "integrates into the lookup instead of doing a query" do
      expect(user.cached_persisted_method).to eq 6

      users = User.includes(:db_cache_persisted_method).to_a
      user_i = users.first

      expect_any_instance_of(DbCachedModelMethods::CachedCall).to receive(:find_cache_by_association_autoload).and_call_original
      allow_any_instance_of(DbCachedModelMethods::CachedCall).to receive(:find_cache_by_query) { raise "find_cache_by query should not be called" }

      expect(user_i.cached_persisted_method).to eq 6
    end
  end

  it "#define_original_method" do
    expect(user.some_method_called).to eq 0
    expect(user.original_some_method).to eq 5
    expect(user.some_method_called).to eq 1
    expect(user.db_caches.for(:some_method).count).to eq 0
  end

  it "#override_with_uncached" do
    expect(user.overridden_method).to eq 7
    expect(user.overwritten_method_called).to eq 1
    expect(user.overridden_method).to eq 7
    expect(user.overwritten_method_called).to eq 1
  end

  it "#overridden_uncached_method" do
    expect(user.overridden_uncached_method).to eq 8
    expect(user.overwritten_uncached_method_called).to eq 1
    expect(user.overridden_uncached_method).to eq 8
    expect(user.overwritten_uncached_method_called).to eq 2
  end
end
