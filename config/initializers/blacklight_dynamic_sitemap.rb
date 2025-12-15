# frozen_string_literal: true

BlacklightDynamicSitemap::Engine.config.tap do |config|
  # New UUID-based apps can use the id field directly for efficient sitemap generation.
  # Apps using Noids need to add hashed_id_ssi to Solr (see gem documentation).
  config.hashed_id_field = if Hyrax.config.enable_noids?
                             # Noid IDs use alphanumeric characters - need separate hashed field
                             'hashed_id_ssi'
                           else
                             # UUID IDs are hex-based - can use id field directly
                             'id'
                           end

  config.hashed_id_field = 'id'
  config.unique_id_field = 'id'

  config.modify_show_params = lambda { |_id, default_params|
    default_params.merge(
      fl: "#{default_params[:fl]},has_model_ssim",
      fq: (default_params[:fq] || []) + [
        'read_access_group_ssim:public',
        '-has_model_ssim:("Hyrax::FileSet" OR "Hyrax::FileMetadata" OR "Hyrax::AdministrativeSet")'
      ]
    )
  }

  config.modify_index_params = lambda { |default_params|
    default_params.merge(
      fq: (default_params[:fq] || []) + [
        'read_access_group_ssim:public',
        '-has_model_ssim:("Hyrax::FileSet" OR "Hyrax::FileMetadata" OR "Hyrax::AdministrativeSet")'
      ]
    )
  }
end
