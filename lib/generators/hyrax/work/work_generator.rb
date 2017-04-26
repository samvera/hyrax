require 'rails/generators'

class Hyrax::WorkGenerator < Rails::Generators::NamedBase
  include Rails::Generators::ModelHelpers

  source_root File.expand_path('../templates', __FILE__)

  argument :attributes, type: :array, default: [], banner: 'field:type field:type'

  # Why all of these antics with defining individual methods?
  # Because I want the output of Hyrax::WorkGenerator to include all the processed files.
  def banner
    if revoking?
      say_status("info", "DESTROYING WORK MODEL: #{class_name}", :blue)
    else
      say_status("info", "GENERATING WORK MODEL: #{class_name}", :blue)
    end
  end

  def create_actor
    template('actor.rb.erb', "app/actors/hyrax/actors/#{file_name}_actor.rb")
  end

  def create_controller
    template('controller.rb.erb', "app/controllers/hyrax/#{plural_file_name}_controller.rb")
  end

  def create_form
    template('form.rb.erb', "app/forms/hyrax/#{file_name}_form.rb")
  end

  def create_model
    template('model.rb.erb', "app/models/#{file_name}.rb")
  end

  def create_views
    create_file "app/views/hyrax/#{plural_file_name}/_#{file_name}.html.erb" do
      "<%# This is a search result view %>\n" \
      "<%= render 'catalog/document', document: #{file_name}, document_counter: #{file_name}_counter  %>\n"
    end
  end

  # Inserts after the last registered work, or at the top of the config block
  def register_work
    config = 'config/initializers/hyrax.rb'
    lastmatch = nil
    in_root do
      File.open(config).each_line do |line|
        lastmatch = line if line =~ /config.register_curation_concern :(?!#{file_name})/
      end
      content = "  # Injected via `rails g hyrax:work #{class_name}`\n" \
                "  config.register_curation_concern :#{file_name}\n"
      anchor = lastmatch || "Hyrax.config do |config|\n"
      inject_into_file config, after: anchor do
        content
      end
    end
  end

  def create_i18n
    template('locale.en.yml.erb', "config/locales/#{file_name}.en.yml")
    template('locale.es.yml.erb', "config/locales/#{file_name}.es.yml")
  end

  def create_actor_spec
    return unless rspec_installed?
    template('actor_spec.rb.erb', "spec/actors/hyrax/actors/#{file_name}_actor_spec.rb")
  end

  def create_controller_spec
    return unless rspec_installed?
    template('controller_spec.rb.erb', "spec/controllers/hyrax/#{plural_file_name}_controller_spec.rb")
  end

  def create_feature_spec
    return unless rspec_installed?
    template('feature_spec.rb.erb', "spec/features/create_#{file_name}_spec.rb")
  end

  def create_form_spec
    return unless rspec_installed?
    template('form_spec.rb.erb', "spec/forms/hyrax/#{file_name}_form_spec.rb")
  end

  def create_model_spec
    return unless rspec_installed?
    template('model_spec.rb.erb', "spec/models/#{file_name}_spec.rb")
  end

  def display_readme
    readme 'README' unless revoking?
  end

  private

    def rspec_installed?
      defined?(RSpec) && defined?(RSpec::Rails)
    end

    def revoking?
      behavior == :revoke
    end
end
