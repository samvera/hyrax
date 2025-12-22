# frozen_string_literal: true
require 'hyrax/model_registry'

def build_model_exclusion_filter
  classes_to_exclude = Hyrax::ModelRegistry.file_set_class_names + Hyrax::ModelRegistry.admin_set_class_names + ["Hyrax::FileMetadata"]
  classes_to_exclude.map!{ |klass| klass.gsub(/^::/, '') }.uniq!
  "-has_model_ssim:(\"#{classes_to_exclude.join('" OR "')}\")"
end

BlacklightDynamicSitemap::Engine.config.tap do |config|
  config.unique_id_field = 'id'

  model_exclusion_filter = build_model_exclusion_filter
  config.modify_show_params = lambda { |_id, default_params|
    default_params.merge(
      fl: "#{default_params[:fl]},has_model_ssim",
      fq: (default_params[:fq] || []) + [
        'read_access_group_ssim:public',
        model_exclusion_filter
      ]
    )
  }
  config.modify_index_params = lambda { |default_params|
    default_params.merge(
      fq: (default_params[:fq] || []) + [
        'read_access_group_ssim:public',
        model_exclusion_filter
      ]
    )
  }
end

Rails.application.config.after_initialize do
  # New UUID-based apps can use the id field directly for efficient sitemap generation.
  # Apps using Noids need to add hashed_id_ssi to Solr (see gem documentation).
  BlacklightDynamicSitemap::Engine.config.hashed_id_field = if Hyrax.config.enable_noids?
                                                              # Noid IDs use alphanumeric characters - need separate hashed field
                                                              'hashed_id_ssi'
                                                            else
                                                              # UUID IDs are hex-based - can use id field directly
                                                              'id'
                                                            end
end
