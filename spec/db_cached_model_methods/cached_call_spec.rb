require "spec_helper"

describe DbCachedModelMethods::CachedCall do
  let(:user) { create :user }

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
end
