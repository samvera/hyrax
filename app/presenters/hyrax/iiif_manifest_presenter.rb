# frozen_string_literal: true

module Hyrax
  ##
  # @example with a work
  #
  #   monograph = Monograph.new
  #   presenter = IiifManifestPresenter.new(monograph)
  #   presenter.title # => []
  #
  #   monograph.title = ['Comet in Moominland']
  #   presenter.title # => ['Comet in Moominland']
  #
  # @see https://www.rubydoc.info/gems/iiif_manifest
  class IiifManifestPresenter < Draper::Decorator
    delegate_all

    ##
    # @return [String]
    def description
      Array(super).first || ''
    end

    ##
    # @return [Boolean]
    def file_set?
      model.try(:file_set?) ||
        Array(model[:has_model_ssim]).include?('FileSet')
    end

    ##
    # @return [Array<IiifManifestPresenter>]
    def file_set_presenters
      member_presenters.select(&:file_set?)
    end

    ##
    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @todo should this use the simple_form i18n keys?! maybe the manifest
    #   needs its own?
    #
    # @return [Array<Hash{String => String}>] array of metadata hashes
    def manifest_metadata
      metadata_fields.map do |field_name|
        {
          'label' => I18n.t("simple_form.labels.defaults.#{field_name}"),
          'value' => Array.wrap(self[field_name]).map { |value| scrub(value.to_s) }
        }
      end
    end

    ##
    # @return [String] the URL where the manifest can be found
    def manifest_url
      return '' if id.blank?

      Rails.application.routes.url_helpers.polymorphic_url([:manifest, model], host: hostname)
    end

    ##
    # @return [Array<#to_s>]
    def member_ids
      Array(model.try(:member_ids))
    end

    ##
    # @note cache member presenters to avoid querying repeatedly; we expect this
    #   presenter to live only as long as the request.
    # @return [Array<IiifManifestPresenter>]
    def member_presenters
      @member_presesnters_cache ||=
        PresenterFactory.build_for(ids: member_ids, presenter_class: self.class)
    end

    ##
    # @return [Array<Hash{String => String}>]
    def sequence_rendering
      Array(try(:rendering_ids)).map do |_file_set_id|
        nil
      end.flatten
    end

    ##
    # @return [Boolean]
    def work?
      object.try(:work?) ||
        !file_set?
    end

    ##
    # @return [Array<IiifManifestPresenter>]
    def work_presenters
      member_presenters.select(&:work?)
    end

    private

      def hostname
        'http://example.com'
      end

      def metadata_fields
        Hyrax.config.iiif_metadata_fields
      end

      def scrub(value)
        Loofah.fragment(value).scrub!(:whitewash).to_s
      end
  end
end
