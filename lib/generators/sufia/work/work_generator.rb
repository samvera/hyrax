require 'generators/curation_concerns/work/work_generator'

module Sufia
  class WorkGenerator < CurationConcerns::WorkGenerator
    source_root CurationConcerns::WorkGenerator.source_root

    # Allows us to pull templates from sufia as well as from curation_concerns
    def self.source_paths
      [File.expand_path('../templates/', __FILE__)]
    end

    desc """
  This generator makes the following changes to your application:
   1. Generates work model
   2. Injects sufia behavior into model
   3. Injects sufia behavior into form
         """

    def create_model
      say_status("info", "GENERATING WORK MODEL", :blue)
      super
    end

    def create_i18n
      template 'locale.en.yml.erb', "config/locales/#{file_name}.en.yml"
    end

    def register_work
      inject_into_file 'config/initializers/sufia.rb', after: "Sufia.config do |config|\n" do
        "  # Injected via `rails g sufia:work #{class_name}`\n" \
        "  config.register_curation_concern :#{file_name}\n"
      end
    end

    def inject_sufia_work_behavior
      underscored_name = name.underscore
      insert_into_file "app/models/#{underscored_name}.rb", after: 'include ::CurationConcerns::BasicMetadata' do
        "\n  include Sufia::WorkBehavior" \
        "\n  self.human_readable_type = '#{underscored_name.titleize}'"
      end
    end

    def inject_sufia_form
      file_path = "app/forms/curation_concerns/#{file_name}_form.rb"
      if File.exist?(file_path)
        gsub_file file_path, /CurationConcerns::Forms::WorkForm/, "Sufia::Forms::WorkForm"
        inject_into_file file_path, after: /model_class = ::.*$/ do
          "\n    self.terms += [:resource_type]\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a #{class_name}Form object. This generator assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def inject_sufia_work_controller_behavior
      file_path = "app/controllers/curation_concerns/#{plural_file_name}_controller.rb"
      if File.exist?(file_path)
        inject_into_file file_path, after: /include CurationConcerns::CurationConcernController/ do
          "\n    # Adds Sufia behaviors to the controller.\n" \
            "    include Sufia::WorksControllerBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a #{controller_class_name} object. This generator assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end
  end
end
