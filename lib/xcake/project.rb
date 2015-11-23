require 'xcodeproj'

module Xcake
  class Project

    include BuildConfigurable
    include Visitable

    attr_accessor :default_build_configuration
    attr_accessor :project_name
    attr_accessor :targets

    def initialize(name="Project", &block)

      self.project_name = name
      self.targets = []

      block.call(self) if block_given?
    end

    def target(&block)
      target = Target.new(&block)
      self.targets << target

      target
    end

    def application_for(platform, deployment_target, language=:objc, &block)

      application_target = target do |t|
        t.type = :application
        t.platform = platform
        t.deployment_target = deployment_target
        t.language = language

        block.call(t) if block_given?
      end

      application_target
    end

    def unit_tests_for(host_target, &block)

      unit_test_target = target do |t|

        t.name = "#{host_target.name}Tests"

        t.type = :unit_test_bundle
        t.platform = host_target.platform
        t.deployment_target = host_target.deployment_target
        t.language = host_target.language

        t.include_files << host_target.include_files
        t.exclude_files << host_target.exclude_files

        t.all_build_configurations.settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/#{host_target.name}.app/#{host_target.name}"
        t.all_build_configurations.settings["BUNDLE_LOADER"] = "$(TEST_HOST)"

        block.call(t) if block_given?
      end

      unit_test_target
    end

    #BuildConfigurable

    def default_settings
      common_settings = Xcodeproj::Constants::PROJECT_DEFAULT_BUILD_SETTINGS
      settings = Xcodeproj::Project::ProjectHelper.deep_dup(common_settings[:all])
    end

    def default_debug_settings
      common_settings = Xcodeproj::Constants::PROJECT_DEFAULT_BUILD_SETTINGS
      default_settings.merge!(Xcodeproj::Project::ProjectHelper.deep_dup(common_settings[:debug]))
    end

    def default_release_settings
      common_settings = Xcodeproj::Constants::PROJECT_DEFAULT_BUILD_SETTINGS
      default_settings.merge!(Xcodeproj::Project::ProjectHelper.deep_dup(common_settings[:release]))
    end

    #Visitable

    def accept(visitor)
      visitor.visit(self)

      self.flatten_build_configurations.each do |c|
        visitor.visit(c)
        visitor.leave(c)
      end

      self.targets.each do |t|
        visitor.visit(t)
        visitor.leave(t)
      end

      visitor.leave(self)
    end
  end
end
