class CreateProxyDepositRights < ActiveRecord::Migration
  def change
    create_table :proxy_deposit_rights do |t|
      t.references :grantor
      t.references :grantee
      t.timestamps
    end
    add_index :proxy_deposit_rights, :grantor_id
    add_index :proxy_deposit_rights, :grantee_id
  end
end
