# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Middleware::Coercion do
  describe ".coerce_value" do
    it "coerces string to integer" do
      expect(described_class.coerce_value("42", {"type" => "integer"})).to eq(42)
    end

    it "coerces string to float" do
      expect(described_class.coerce_value("3.14", {"type" => "number"})).to eq(3.14)
    end

    it "coerces string to boolean true" do
      expect(described_class.coerce_value("true", {"type" => "boolean"})).to be true
    end

    it "coerces string to boolean false" do
      expect(described_class.coerce_value("false", {"type" => "boolean"})).to be false
    end

    it "returns original value for unknown types" do
      expect(described_class.coerce_value("hello", {"type" => "string"})).to eq("hello")
    end

    it "returns original value on coercion failure" do
      expect(described_class.coerce_value("not_a_number", {"type" => "integer"})).to eq("not_a_number")
    end

    it "handles nil schema" do
      expect(described_class.coerce_value("42", nil)).to eq("42")
    end
  end

  describe ".coerce_params" do
    it "coerces matching parameters" do
      params = {"page" => "1", "name" => "Jane"}
      parameters = [
        {"name" => "page", "in" => "query", "schema" => {"type" => "integer"}},
        {"name" => "name", "in" => "query", "schema" => {"type" => "string"}}
      ]

      result = described_class.coerce_params(params, parameters)

      expect(result["page"]).to eq(1)
      expect(result["name"]).to eq("Jane")
    end

    it "passes through params without specs" do
      params = {"unknown" => "value"}
      result = described_class.coerce_params(params, [])

      expect(result["unknown"]).to eq("value")
    end
  end
end
