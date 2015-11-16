require "spec_helper"

describe DbCachedModelMethods::ClassMethods do
  let(:user) { create :user }
  let(:some_method) { User.db_cached_model_method(:some_method) }
  let(:method_that_requires_args) { User.db_cached_model_method(:method_that_requires_args) }
  let(:expires_in_proc_method) { User.db_cached_model_method(:expires_in_proc_method) }
  let(:persisted_method) { User.db_cached_model_method(:persisted_method) }

  describe "#cache_method_in_db" do
    it "reads 'require_args' correctly" do
      expect(some_method.fetch(:require_args)).to eq false
      expect(method_that_requires_args.fetch(:require_args)).to eq true
    end

    it "reads 'expires_in' correctly" do
      expect(some_method.fetch(:expires_in)).to eq 1.hour
      expect(expires_in_proc_method.fetch(:expires_in)).to be_a Proc
      expect(persisted_method.fetch(:expires_in)).to eq 2.hours
    end
  end
end
