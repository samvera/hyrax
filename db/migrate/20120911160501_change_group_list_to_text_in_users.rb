class ChangeGroupListToTextInUsers  < ActiveRecord::Migration
  def self.up
    change_column :users,  :group_list, :text
  end

end
