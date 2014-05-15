module Worthwhile::SearchPathsHelper

  def search_path_for_my_works
    main_app.catalog_index_path(:'f[generic_type_sim][]' => 'Work', works: 'mine')
  end

  def search_path_for_my_collections
    main_app.catalog_index_path(:'f[generic_type_sim][]' => 'Collection', works: 'mine')
  end

end