# frozen_string_literal: true
# If you want to move all your works to an admin set run this.
class MoveAllWorksToAdminSet
  def self.run(admin_set)
    Hyrax::WorkRelation.new.find_each do |w|
      w.update(admin_set: admin_set)
    end
  end
end
