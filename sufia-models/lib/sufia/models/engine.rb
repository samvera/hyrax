module Sufia
  module Models
    def self.config(&block)
      @@config ||= Engine::Configuration.new

      yield @@config if block

      return @@config
    end

    class Engine < ::Rails::Engine
      config.autoload_paths += %W(
        #{config.root}/lib/sufia/models/jobs
      )

      rake_tasks do
        load File.expand_path('../../../tasks/sufia-models_tasks.rake', __FILE__)
      end

      initializer "patches" do
        require 'sufia/models/active_fedora/redis'
        require 'sufia/models/active_record/redis'
        require 'sufia/models/active_support/core_ext/marshal'
      end

      initializer 'requires' do
        require 'sufia/models/model_methods'
        require 'sufia/models/noid'
        require 'sufia/models/file_content'
        require 'sufia/models/file_content/extract_metadata'
        require 'sufia/models/file_content/versions'
        require 'sufia/models/generic_file/actions'
        require 'sufia/models/generic_file/audit'
        require 'sufia/models/generic_file/characterization'
        require 'sufia/models/generic_file/export'
        require 'sufia/models/generic_file/permissions'
        require 'sufia/models/generic_file/thumbnail'
        require 'sufia/models/generic_file'
        require 'sufia/models/user'
        require 'sufia/models/id_service'
        require 'sufia/models/solr_document_behavior'
      end
    end
  end
end
