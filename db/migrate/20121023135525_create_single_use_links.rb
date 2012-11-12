class CreateSingleUseLinks < ActiveRecord::Migration
  def change
    create_table :single_use_links do |t|
      t.string :downloadKey
      t.string :path
      t.string :itemId
      t.datetime :expires

      t.timestamps
    end
  end
end
