# frozen_string_literal: true

BlacklightDynamicSitemap::Engine.config.tap do |config|
  # Use the existing 'id' field for both hashing and unique ID
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
