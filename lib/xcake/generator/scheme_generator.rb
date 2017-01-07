module Xcake
  class SchemeGenerator < Generator
    def self.dependencies
      [TargetGenerator, DefaultProjectStructureGenerator, ConfigurationGenerator]
    end

    def visit_project(project)
      EventHooks.run_hook :before_adding_user_schemes
      @project = @context.native_object_for(project)
    end

    def visit_target(target)
      scheme_list = @context.scheme_list
      native_target = @context.native_object_for(target)

      scheme_list.supress_autocreation_of_target(native_target)

      target.schemes.each do |scheme| 

        native_scheme = @context.native_object_for(scheme)
        native_scheme.name = scheme.name

          #TODO: Find multiple testing targets, move this into the DSL ?
          unit_test_target = @project.find_unit_test_target_for_target(target)
          native_unit_test_target = @context.native_object_for(unit_test_target)

          if native_unit_test_target
            scheme_list.supress_autocreation_of_target(native_unit_test_target)
          end

          native_scheme.configure_with_targets(native_target, native_unit_test_target)
          native_scheme.test_action.build_configuration = scheme.test_configuration
          native_scheme.launch_action.build_configuration = scheme.launch_configuration
          native_scheme.profile_action.build_configuration = scheme.profile_configuration
          native_scheme.analyze_action.build_configuration = scheme.analyze_configuration
          native_scheme.archive_action.build_configuration = scheme.archive_configuration

          scheme_list.schemes << native_scheme
      end
    end

    def leave_project(project)
      scheme_list = @context.scheme_list
      scheme_list.save
    end
  end
end
