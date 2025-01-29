# frozen_string_literal: true
require 'rails/generators'

class Hyrax::ConfigGenerator < Rails::Generators::Base
  desc """
    This generator installs the hyrax configuration files into your application for:
    * Hyrax initializers
    * Citations
    * SimpleForm
    * controlled authorities
    * Admin stats
    * Mini-magick
    * TinyMCE
    * i18n
    * Valkyrie index
       """

  source_root File.expand_path('../templates', __FILE__)

  def local_authorities
    copy_file "config/authorities/licenses.yml"
    copy_file "config/authorities/rights_statements.yml"
    copy_file "config/authorities/resource_types.yml"
  end

  def simple_form_initializers
    copy_file 'config/initializers/simple_form.rb'
    copy_file 'config/initializers/simple_form_bootstrap.rb'
  end

  def configure_endnote
    append_file 'config/initializers/mime_types.rb',
                "\nMime::Type.register 'application/x-endnote-refer', :endnote", verbose: false
  end

  def configure_redis
    copy_file 'config/redis.yml'
    copy_file 'config/initializers/redis_config.rb'
  end

  def configure_valkyrie
    copy_file 'config/initializers/1_valkyrie.rb'
  end

  def configure_valkyrie_index
    copy_file 'config/valkyrie_index.yml'
    copy_file 'config/solr_wrapper_valkyrie_test.yml'
  end

  def metadata_dir
    empty_directory 'config/metadata'
  end

  def derivatives_file_services
    copy_file 'config/initializers/file_services.rb'
  end

  def create_initializer_config_file
    copy_file 'config/initializers/hyrax.rb'
  end

  def tinymce_config
    copy_file 'config/tinymce.yml'
  end

  def inject_i18n
    copy_file 'config/locales/hyrax.en.yml'
    copy_file 'config/locales/hyrax.es.yml'
    copy_file 'config/locales/hyrax.zh.yml'
    copy_file 'config/locales/hyrax.de.yml'
    copy_file 'config/locales/hyrax.fr.yml'
    copy_file 'config/locales/hyrax.it.yml'
    copy_file 'config/locales/hyrax.pt-BR.yml'
  end
end
