# frozen_string_literal: true
class AddDisplayUrlToHyraxRedirectPaths < ActiveRecord::Migration[5.2]
  def change
    add_column :hyrax_redirect_paths, :display_url, :boolean, default: false, null: false
  end
end
