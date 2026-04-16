# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Testing::Coverage do
  let(:document) do
    {
      "paths" => {
        "/users" => {
          "get" => {"responses" => {"200" => {}, "401" => {}}},
          "post" => {"responses" => {"201" => {}, "422" => {}}}
        },
        "/users/{id}" => {
          "get" => {"responses" => {"200" => {}, "404" => {}}}
        }
      }
    }
  end

  subject(:coverage) { described_class.new(document) }

  describe "#total" do
    it "extracts all endpoint/status combinations" do
      expect(coverage.total.size).to eq(6)
    end
  end

  describe "#record" do
    it "tracks covered endpoints" do
      coverage.record(:get, "/users", 200)
      expect(coverage.covered.size).to eq(1)
    end
  end

  describe "#uncovered" do
    it "returns untested endpoints" do
      coverage.record(:get, "/users", 200)
      coverage.record(:get, "/users", 401)

      expect(coverage.uncovered.size).to eq(4)
    end
  end

  describe "#percentage" do
    it "calculates coverage percentage" do
      coverage.record(:get, "/users", 200)
      coverage.record(:get, "/users", 401)
      coverage.record(:post, "/users", 201)

      expect(coverage.percentage).to eq(50.0)
    end

    it "returns 100 for empty specs" do
      empty_coverage = described_class.new({"paths" => {}})
      expect(empty_coverage.percentage).to eq(100.0)
    end
  end

  describe "#report" do
    it "returns a summary hash" do
      coverage.record(:get, "/users", 200)
      report = coverage.report

      expect(report[:total]).to eq(6)
      expect(report[:covered]).to eq(1)
      expect(report[:uncovered]).to eq(5)
      expect(report[:missing]).to be_an(Array)
    end
  end
end
