require "spec_helper"

describe DbCachedModelMethods::CacheBuilder do
  let!(:user) { create :user }
  let(:builder) { DbCachedModelMethods::CacheBuilder.new(model_class: User, method: :some_method) }

  it "#execute" do
    builder.execute
    expect(user.db_caches.for("some_method").count).to eq 1
  end
end
