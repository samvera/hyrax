class CreatePermissionTemplate < ActiveRecord::Migration
  def change
    create_table :permission_templates do |t|
      t.string :admin_set_id
      t.string :visibility
      t.timestamps
    end
    add_index :permission_templates, :admin_set_id
  end
end
