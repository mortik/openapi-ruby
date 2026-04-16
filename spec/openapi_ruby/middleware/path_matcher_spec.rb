# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Middleware::PathMatcher do
  describe "#match" do
    it "matches exact paths" do
      matcher = described_class.new(["/users", "/posts"])
      result = matcher.match("/users")

      expect(result).to eq(["/users", {}])
    end

    it "matches paths with parameters" do
      matcher = described_class.new(["/users/{id}"])
      result = matcher.match("/users/42")

      expect(result).to eq(["/users/{id}", {"id" => "42"}])
    end

    it "matches paths with multiple parameters" do
      matcher = described_class.new(["/users/{user_id}/posts/{post_id}"])
      result = matcher.match("/users/5/posts/99")

      expect(result).to eq(["/users/{user_id}/posts/{post_id}", {"user_id" => "5", "post_id" => "99"}])
    end

    it "returns nil for unmatched paths" do
      matcher = described_class.new(["/users", "/posts"])
      result = matcher.match("/comments")

      expect(result).to be_nil
    end

    it "does not match partial paths" do
      matcher = described_class.new(["/users"])
      result = matcher.match("/users/extra")

      expect(result).to be_nil
    end

    it "handles URL-encoded path params" do
      matcher = described_class.new(["/users/{name}"])
      result = matcher.match("/users/Jane%20Doe")

      expect(result).to eq(["/users/{name}", {"name" => "Jane Doe"}])
    end
  end
end
