# Responsible for copying the following attributes from the work to each file in the file_sets
#
# * visibility
# * lease
# * embargo
class VisibilityCopyJob < Hyrax::ApplicationJob
  # @api public
  # @param [#file_sets, #visibility, #lease, #embargo] work - a Work model
  def perform(work)
    work.file_sets.each do |file|
      file.visibility = work.visibility # visibility must come first, because it can clear an embargo/lease
      copy_visibility_modifier(work: work, file: file, modifier: :lease)
      copy_visibility_modifier(work: work, file: file, modifier: :embargo)
      file.save!
    end
  end

  private

    def copy_visibility_modifier(work:, file:, modifier:)
      work_modifier = work.public_send(modifier)
      return unless work_modifier
      file.public_send("build_#{modifier}") unless file.public_send(modifier)
      file.public_send(modifier).attributes = work_modifier.attributes.except('id')
      file.public_send(modifier).save
    end
end
