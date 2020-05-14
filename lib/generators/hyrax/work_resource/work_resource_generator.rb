require 'rails/generators'
require 'rails/generators/model_helpers'

class Hyrax::WorkResourceGenerator < Rails::Generators::NamedBase
  # ActiveSupport can interpret models as plural which causes
  # counter-intuitive route paths. Pull in ModelHelpers from
  # Rails which warns users about pluralization when generating
  # new models or scaffolds.
  include Rails::Generators::ModelHelpers

  source_root File.expand_path('../templates', __FILE__)

  argument :attributes, type: :array, default: [], banner: 'field:type field:type'

  def banner
    if revoking?
      say_status("info", "DESTROYING VALKYRIE WORK MODEL: #{class_name}", :blue)
    else
      say_status("info", "GENERATING VALKYRIE WORK MODEL: #{class_name}", :blue)
    end
  end

  def create_controller
    template('controller.rb.erb', File.join('app/controllers/hyrax', class_path, "#{plural_file_name}_controller.rb"))
  end

  def create_model
    template('work.rb.erb', File.join('app/models/', class_path, "#{file_name}.rb"))
  end

  def create_model_spec
    template('work_spec.rb.erb', File.join('spec/models/', class_path, "#{file_name}_spec.rb")) if
      rspec_installed?
  end

  def create_form
    template('form.rb.erb', File.join('app/forms/', class_path, "#{file_name}_form.rb"))
  end

  # Inserts after the last registered work, or at the top of the config block
  def register_work
    config = 'config/initializers/hyrax.rb'
    lastmatch = nil
    in_root do
      File.open(config).each_line do |line|
        lastmatch = line if line.match?(/config.register_curation_concern :(?!#{file_name})/)
      end
      content = "  # Injected via `rails g hyrax:work_resource #{class_name}`\n" \
                "  config.register_curation_concern #{registration_path_symbol}\n"
      anchor = lastmatch || "Hyrax.config do |config|\n"
      inject_into_file config, after: anchor do
        content
      end
    end
  end

  def create_indexer
    template('indexer.rb.erb', File.join('app/indexers/', class_path, "#{file_name}_indexer.rb"))
  end

  def register_indexer
    config = 'config/initializers/hyrax.rb'
    register_line = "Hyrax::ValkyrieIndexer.register #{class_name}Indexer, as_indexer_for: #{class_name}\n"

    return if File.read(config).include?(register_line)

    append_to_file config do
      register_line
    end
  end

  def create_views
    create_file File.join('app/views/hyrax', class_path, "#{plural_file_name}/_#{file_name}.html.erb") do
      "<%# This is a search result view %>\n" \
      "<%= render 'catalog/document', document: #{file_name}, document_counter: #{file_name}_counter  %>\n"
    end
  end

  def create_view_spec
    return unless rspec_installed?
    template('work.html.erb_spec.rb.erb',
             File.join('spec/views/', class_path, "#{plural_file_name}/_#{file_name}.html.erb_spec.rb"))
  end

  private

    def rspec_installed?
      defined?(RSpec) && defined?(RSpec::Rails)
    end

    def registration_path_symbol
      return ":#{file_name}" if class_path.blank?
      # creates a symbol with a path like "abc/scholarly_paper" where abc
      # is the namespace and scholarly_paper is the resource name
      ":\"#{File.join(class_path, file_name)}\""
    end

    def revoking?
      behavior == :revoke
    end
end
