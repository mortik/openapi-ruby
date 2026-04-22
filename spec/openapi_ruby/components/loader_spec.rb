# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe OpenapiRuby::Components::Loader do
  before do
    OpenapiRuby::Components::Registry.instance.clear!
  end

  describe "scope inference from directory structure" do
    let(:tmpdir) { Dir.mktmpdir("api_components") }

    after { FileUtils.rm_rf(tmpdir) }

    def write_component(path, class_name, module_nesting: nil, scope: nil)
      full_path = File.join(tmpdir, path)
      FileUtils.mkdir_p(File.dirname(full_path))

      scope_line = scope ? "        component_scopes :#{scope}" : ""
      module_open = module_nesting ? "module #{module_nesting}\n" : ""
      module_close = module_nesting ? "end\n" : ""

      content = "#{module_open}class #{class_name}\n" \
        "  include OpenapiRuby::Components::Base\n" \
        "#{scope_line}\n" \
        "  schema(type: :object)\n" \
        "end\n" \
        "#{module_close}\n"
      File.write(full_path, content)
    end

    it "infers scopes from directory prefixes" do
      write_component("v1/schemas/user.rb", "InferredV1User")
      write_component("admin/v1/schemas/user.rb", "InferredAdminUser")
      write_component("shared/v1/schemas/error.rb", "InferredSharedError")

      OpenapiRuby.configuration.component_scope_paths = {
        "v1" => :v1,
        "admin/v1" => :admin,
        "shared/v1" => :shared
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      v1_user = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "InferredV1User" }
      admin_user = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "InferredAdminUser" }
      shared_error = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "InferredSharedError" }

      expect(v1_user._component_scopes).to eq([:v1])
      expect(admin_user._component_scopes).to eq([:admin])
      # :shared scope means empty scopes (included in all specs)
      expect(shared_error._component_scopes).to eq([])
    end

    it "does not override explicitly set scopes" do
      write_component("v1/schemas/explicit.rb", "ExplicitScopeComp", scope: :custom)

      OpenapiRuby.configuration.component_scope_paths = {
        "v1" => :v1
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "ExplicitScopeComp" }
      expect(comp._component_scopes).to eq([:custom])
    end

    it "does not infer scopes when component_scope_paths is empty" do
      write_component("v1/schemas/noinfer.rb", "NoInferComp")

      OpenapiRuby.configuration.component_scope_paths = {}

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "NoInferComp" }
      expect(comp._component_scopes).to eq([])
    end

    it "does not misattribute parent scope when child inherits cross-scope" do
      # Simulate cross-scope inheritance where loading the admin file also loads
      # the parent class (e.g., via Ruby autoloading). The admin file requires
      # the v1 file, so both classes appear in the diff for the admin file.
      # The Loader should still assign :v1 scope to the parent based on its
      # conventional file path, not the file that triggered its loading.
      v1_path = File.join(tmpdir, "v1/schemas/base_item.rb")
      FileUtils.mkdir_p(File.dirname(v1_path))
      File.write(v1_path, <<~RUBY)
        module V1
          module Schemas
            class BaseItem
              include OpenapiRuby::Components::Base
              schema(type: :object)
            end
          end
        end
      RUBY

      admin_path = File.join(tmpdir, "admin/v1/schemas/base_item.rb")
      FileUtils.mkdir_p(File.dirname(admin_path))
      # The admin file explicitly requires the v1 file (simulating autoloading)
      File.write(admin_path, <<~RUBY)
        require "#{v1_path}"
        module Admin
          module V1
            module Schemas
              class BaseItem < ::V1::Schemas::BaseItem
                schema(type: :object)
              end
            end
          end
        end
      RUBY

      OpenapiRuby.configuration.component_scope_paths = {
        "v1" => :v1,
        "admin/v1" => :admin
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      v1_comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "V1::Schemas::BaseItem" }
      admin_comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "Admin::V1::Schemas::BaseItem" }

      expect(v1_comp._component_scopes).to eq([:v1])
      expect(admin_comp._component_scopes).to eq([:admin])
    end

    it "sets explicitly_set for shared scope components" do
      write_component("shared/v1/schemas/shared_item.rb", "SharedItem")

      OpenapiRuby.configuration.component_scope_paths = {
        "shared/v1" => :shared
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "SharedItem" }
      expect(comp._component_scopes).to eq([])
      expect(comp._component_scopes_explicitly_set).to be true
    end

    it "assigns multiple scopes when component_scope_paths value is an array" do
      write_component("shared/v1/schemas/multi_scope.rb", "MultiScopeComp")

      OpenapiRuby.configuration.component_scope_paths = {
        "shared/v1" => [:v1, :admin]
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "MultiScopeComp" }
      expect(comp._component_scopes).to eq([:v1, :admin])
      expect(comp._component_scopes_explicitly_set).to be true
    end
  end
end
