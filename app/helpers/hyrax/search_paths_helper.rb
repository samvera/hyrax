module Hyrax::SearchPathsHelper
  def search_path_for_my_works(opts = {})
    params_for_my_works = { 'f[generic_type_sim][]' => 'Work', works: 'mine' }
    main_app.search_catalog_path(params_for_my_works.merge(opts))
  end

  def search_path_for_my_collections(opts = {})
    params_for_my_collections = { 'f[generic_type_sim][]' => 'Collection', works: 'mine' }
    main_app.search_catalog_path(params_for_my_collections.merge(opts))
  end
end
