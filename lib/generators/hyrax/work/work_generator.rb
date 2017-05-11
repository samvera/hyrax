require 'rails/generators'
require 'rails/generators/model_helpers'

class Hyrax::WorkGenerator < Rails::Generators::NamedBase
  # ActiveSupport can interpret models as plural which causes
  # counter-intuitive route paths. Pull in ModelHelpers from
  # Rails which warns users about pluralization when generating
  # new models or scaffolds.  include Rails::Generators::ModelHelpers
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
    template('actor.rb.erb', File.join('app/actors/hyrax/actors', class_path, "#{file_name}_actor.rb"))
  end

  def create_controller
    template('controller.rb.erb', File.join('app/controllers/hyrax', class_path, "#{plural_file_name}_controller.rb"))
  end

  def create_form
    template('form.rb.erb', File.join('app/forms/hyrax', class_path, "#{file_name}_form.rb"))
  end

  def create_model
    template('model.rb.erb', File.join('app/models', class_path, "#{file_name}.rb"))
  end

  def create_views
    create_file File.join('app/views/hyrax', class_path, "#{plural_file_name}/_#{file_name}.html.erb") do
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
                "  config.register_curation_concern #{registration_path_symbol}\n"
      anchor = lastmatch || "Hyrax.config do |config|\n"
      inject_into_file config, after: anchor do
        content
      end
    end
  end

  def create_i18n
    template('locale.en.yml.erb', File.join('config/locales/', class_path, "#{file_name}.en.yml"))
    template('locale.es.yml.erb', File.join('config/locales/', class_path, "#{file_name}.es.yml"))
    template('locale.zh.yml.erb', File.join('config/locales/', class_path, "#{file_name}.zh.yml"))
  end

  def create_actor_spec
    return unless rspec_installed?
    template('actor_spec.rb.erb', File.join('spec/actors/hyrax/actors', class_path, "#{file_name}_actor_spec.rb"))
  end

  def create_controller_spec
    return unless rspec_installed?
    template('controller_spec.rb.erb', File.join('spec/controllers/hyrax', class_path, "#{plural_file_name}_controller_spec.rb"))
  end

  def create_feature_spec
    return unless rspec_installed?
    template('feature_spec.rb.erb', File.join('spec/features', class_path, "create_#{file_name}_spec.rb"))
  end

  def create_form_spec
    return unless rspec_installed?
    template('form_spec.rb.erb', File.join('spec/forms/hyrax', class_path, "#{file_name}_form_spec.rb"))
  end

  def create_model_spec
    return unless rspec_installed?
    template('model_spec.rb.erb', File.join('spec/models', class_path, "#{file_name}_spec.rb"))
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

    def registration_path_symbol
      return ":#{file_name}" if class_path.blank?
      # this next line creates a symbol with a path like
      # "abc/scholarly_paper" where abc is the namespace and
      #                              scholarly_paper is the concern
      ":\"#{File.join(class_path, file_name)}\""
    end
end
