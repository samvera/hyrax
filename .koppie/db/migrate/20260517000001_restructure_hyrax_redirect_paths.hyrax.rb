# frozen_string_literal: true

class RestructureHyraxRedirectPaths < ActiveRecord::Migration[5.2]
  def up
    rename_column :hyrax_redirect_paths, :path, :source_path

    add_column :hyrax_redirect_paths, :target_path, :string
    add_column :hyrax_redirect_paths, :display, :boolean, null: false, default: false

    add_index :hyrax_redirect_paths, :target_path
  end

  def down
    remove_index :hyrax_redirect_paths, :target_path

    remove_column :hyrax_redirect_paths, :display
    remove_column :hyrax_redirect_paths, :target_path

    rename_column :hyrax_redirect_paths, :source_path, :path
  end
end
