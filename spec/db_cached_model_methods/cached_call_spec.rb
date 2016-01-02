require "spec_helper"

describe DbCachedModelMethods::CachedCall do
  let(:organization) { create :organization }
  let(:user) { create :user, organization: organization }

  describe "expires_in" do
    it "supports procs" do
      user.expires_in_expire = 1.day.ago

      expect(user.db_caches.for("expires_in_proc_method").count).to eq 0
      expect(user.expires_in_proc_method_called).to eq 0
      expect(user.cached_expires_in_proc_method).to eq 8
      expect(user.db_caches.for("expires_in_proc_method").count).to eq 1
      expect(user.expires_in_proc_method_called).to eq 1

      expect(user.cached_expires_in_proc_method).to eq 8
      expect(user.db_caches.for("expires_in_proc_method").count).to eq 1
      expect(user.expires_in_proc_method_called).to eq 2
    end
  end

  it "#call_original_through_octopus" do
    expect_any_instance_of(DbCachedModelMethods::CachedCall).to receive(:call_original_through_octopus).and_call_original
    expect(user.cached_method_with_slave_db).to eq 10
  end

  it "retries when record isnt unique" do
    expect(user.db_caches.for("some_method").count).to eq 0

    user = organization.users.includes(:db_caches).first
    expect(user.db_caches.size).to eq 1

    user_other_ref = User.find(user.id)
    expect { user_other_ref.cached_some_method }.to change { user_other_ref.db_caches.count }.by(1)

    user.cached_some_method
  end
end
