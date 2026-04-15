# frozen_string_literal: true

# Runs the dummy app's Minitest integration tests as a subprocess to prove
# the Minitest adapter works end-to-end with a real Rails app.

require "spec_helper"

RSpec.describe "Minitest Posts API integration" do
  it "runs the Posts API Minitest suite successfully" do
    test_file = File.expand_path("../dummy/test/integration/posts_test.rb", __dir__)
    test_dir = File.expand_path("../dummy/test", __dir__)
    env = {"RAILS_ENV" => "test", "BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __dir__)}

    output = IO.popen(env, ["bundle", "exec", "ruby", "-I", test_dir, test_file], err: [:child, :out], &:read)
    status = $?

    expect(status.success?).to be(true),
      "Minitest PostsApiTest failed (exit #{status.exitstatus}):\n#{output}"
  end
end
