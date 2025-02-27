# frozen_string_literal: true
require_relative 'downloader'
require 'rdf/rdfxml'
module Hyrax
  module ControlledVocabulary
    module Importer
      class Language
        URL = 'http://www.lexvo.org/resources/lexvo_2013-02-09.rdf.gz'

        def initialize
          stdout_logger = Logger.new(STDOUT)
          stdout_logger.level = Logger::INFO
          stdout_logger.formatter = proc do |_severity, _datetime, _progname, msg|
            "#{msg}\n"
          end
          ActiveSupport::BroadcastLogger.new(Hyrax.logger, stdout_logger)
        end

        def import
          download
          extract
          logger.info "Importing #{rdf_path}"
          Qa::Services::RDFAuthorityParser.import_rdf(
            'languages',
            [rdf_path],
            format: 'rdfxml',
            predicate: RDF::URI('http://www.w3.org/2008/05/skos#prefLabel')
          )
          logger.info "Import complete"
        end

        delegate :logger, to: Rails

        def rdf_path
          @rdf_path ||= download_path.sub(/\.gz$/, '')
        end

        def extract
          return if File.exist?(rdf_path)
          logger.info "Extracting #{download_path}"
          system("gunzip #{download_path}")
          raise "Unable to extract #{download_path}" unless $CHILD_STATUS.success?
        end

        def download
          return if File.exist?(rdf_path) || File.exist?(download_path)
          logger.info "Downloading #{URL}"
          Downloader.fetch(URL, download_path)
        end

        def download_path
          File.join(download_dir, File.basename(URL))
        end

        def download_dir
          @download_dir ||= Rails.root.join('tmp')
          FileUtils.mkdir_p @download_dir
          @download_dir
        end
      end
    end
  end
end
