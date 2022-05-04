# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/model_helpers'

class Hyrax::CollectionResourceGenerator < Rails::Generators::NamedBase # rubocop:disable Metrics/ClassLength
  # ActiveSupport can interpret models as plural which causes
  # counter-intuitive route paths. Pull in ModelHelpers from
  # Rails which warns users about pluralization when generating
  # new models or scaffolds.
  include Rails::Generators::ModelHelpers

  source_root File.expand_path('../templates', __FILE__)

  argument :with_basic_metadata, type: :string, default: "", banner: 'with_basic_metadata'

  desc 'This generator makes the following changes to your application:
   1. Creates a collection model and model spec, optionally including basic metadata.
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
    filepath = File.join('app/models', "#{file_name}.rb")
    template('collection.rb.erb', filepath)
    return unless include_basic_metadata?
    inject_into_file filepath, before: /include Hyrax::Schema/ do
      "include Hyrax::Schema(:basic_metadata)\n  "
    end
  end

  def create_model_spec
    return unless rspec_installed?
    filepath = File.join('spec/models/', "#{file_name}_spec.rb")
    template('collection_spec.rb.erb', filepath)

    return unless include_basic_metadata?
    inject_into_file filepath, after: /it_behaves_like 'a Hyrax::PcdmCollection'/ do
      "\n  it_behaves_like 'a model with basic metadata'"
    end
  end

  def create_form
    filepath = File.join('app/forms/', "#{file_name}_form.rb")
    template('collection_form.rb.erb', filepath)
    return unless include_basic_metadata?
    inject_into_file filepath, before: /include Hyrax::FormFields/ do
      "include Hyrax::FormFields(:basic_metadata)\n  "
    end
  end

  # @todo If shared specs are expanded to test for basic metadata, inject calling that test here.
  def create_form_spec
    return unless rspec_installed?
    template('collection_form_spec.rb.erb', File.join('spec/forms/', "#{file_name}_form_spec.rb"))
  end

  def create_indexer
    filepath = File.join('app/indexers/', "#{file_name}_indexer.rb")
    template('collection_indexer.rb.erb', filepath)
    return unless include_basic_metadata?
    inject_into_file filepath, before: /include Hyrax::Indexer/ do
      "include Hyrax::Indexer(:basic_metadata)\n  "
    end
  end

  def create_indexer_spec
    return unless rspec_installed?
    filepath = File.join('spec/indexers/', "#{file_name}_indexer_spec.rb")
    template('collection_indexer_spec.rb.erb', filepath)

    return unless include_basic_metadata?
    inject_into_file filepath, after: /it_behaves_like 'a Hyrax::Resource indexer'/ do
      "\n  it_behaves_like 'a Basic metadata indexer'"
    end
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

  def include_basic_metadata?
    with_basic_metadata.present? && with_basic_metadata == "with_basic_metadata"
  end

  def rspec_installed?
    defined?(RSpec) && defined?(RSpec::Rails)
  end

  def revoking?
    behavior == :revoke
  end
end
