# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::DSL::MetadataStore do
  before { described_class.clear! }

  describe ".register / .all_contexts" do
    it "stores and retrieves contexts" do
      ctx = OpenapiRuby::DSL::Context.new("/users")
      described_class.register(ctx)

      expect(described_class.all_contexts).to eq([ctx])
    end
  end

  describe ".contexts_for" do
    it "returns contexts matching spec name" do
      public_ctx = OpenapiRuby::DSL::Context.new("/users", schema_name: :public)
      admin_ctx = OpenapiRuby::DSL::Context.new("/admin", schema_name: :admin)
      described_class.register(public_ctx)
      described_class.register(admin_ctx)

      expect(described_class.contexts_for(:public)).to eq([public_ctx])
    end

    it "includes contexts without a schema name (global)" do
      global_ctx = OpenapiRuby::DSL::Context.new("/health")
      public_ctx = OpenapiRuby::DSL::Context.new("/users", schema_name: :public)
      described_class.register(global_ctx)
      described_class.register(public_ctx)

      result = described_class.contexts_for(:public)

      expect(result).to include(global_ctx, public_ctx)
    end
  end

  describe ".clear!" do
    it "removes all contexts" do
      described_class.register(OpenapiRuby::DSL::Context.new("/a"))
      described_class.clear!

      expect(described_class.all_contexts).to be_empty
    end
  end
end
