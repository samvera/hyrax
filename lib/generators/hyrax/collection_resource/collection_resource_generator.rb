# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/model_helpers'

class Hyrax::CollectionResourceGenerator < Rails::Generators::NamedBase
  # ActiveSupport can interpret models as plural which causes
  # counter-intuitive route paths. Pull in ModelHelpers from
  # Rails which warns users about pluralization when generating
  # new models or scaffolds.
  include Rails::Generators::ModelHelpers

  source_root File.expand_path('../templates', __FILE__)

  desc 'This generator makes the following changes to your application:
   1. Creates a collection model and spec.
   2. Creates a collection form and spec.
   3. Creates a collection indexer and spec.
   4. Creates a collection metadata config.
   5. Sets this to be the collection class.
'

  def self.exit_on_failure?
    true
  end

  def validate_name
    return unless name.strip.casecmp("collection").zero?
    raise Thor::MalformattedArgumentError,
          set_color("Error: A collection resource with the name '#{name}' would cause name-space clashes. "\
                    "Please use a different name.", :red)
  end

  def banner
    if revoking?
      say_status("info", "DESTROYING VALKYRIE COLLECTION MODEL: #{class_name}", :blue)
    else
      say_status("info", "GENERATING VALKYRIE COLLECTION MODEL: #{class_name}", :blue)
    end
  end

  def create_metadata_config
    template('collection_metadata.yaml', File.join('config/metadata/', "#{file_name}.yaml"))
  end

  def create_model
    template('collection.rb.erb', File.join('app/models/', "#{file_name}.rb"))
    return unless rspec_installed?
    template('collection_spec.rb.erb', File.join('spec/models/', "#{file_name}_spec.rb"))
  end

  def create_form
    template('collection_form.rb.erb', File.join('app/forms/', "#{file_name}_form.rb"))
    return unless rspec_installed?
    template('collection_form_spec.rb.erb', File.join('spec/forms/', "#{file_name}_form_spec.rb"))
  end

  def create_indexer
    template('collection_indexer.rb.erb', File.join('app/indexers/', class_path, "#{file_name}_indexer.rb"))
    return unless rspec_installed?
    template('collection_indexer_spec.rb.erb', File.join('spec/indexers/', "#{file_name}_indexer_spec.rb"))
  end

  # Inserts after the last registered work, or at the top of the config block
  def set_as_the_collection_class
    config = 'config/initializers/hyrax.rb'
    lastmatch = nil
    in_root do
      File.open(config).each_line do |line|
        lastmatch = line if line.match?(/config.collection_model = /)
      end
      content = "  # Injected via `rails g hyrax:collection_resource #{class_name}`\n" \
                "  config.collection_model = '#{class_name}'\n"

      anchor = lastmatch || "Hyrax.config do |config|\n"
      inject_into_file config, after: anchor do
        content
      end
    end
  end

  private

  def rspec_installed?
    defined?(RSpec) && defined?(RSpec::Rails)
  end

  def revoking?
    behavior == :revoke
  end
end
