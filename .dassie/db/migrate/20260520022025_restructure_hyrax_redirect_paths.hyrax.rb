class RestructureHyraxRedirectPaths < ActiveRecord::Migration[5.2]
  def change
    rename_column :hyrax_redirect_paths, :path, :source_path

    add_column :hyrax_redirect_paths, :target_path, :string
    add_column :hyrax_redirect_paths, :display_url, :boolean, default: false, null: false
  end
end
