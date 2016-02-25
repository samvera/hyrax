# validates that the title has at least one title
class HasOneTitleValidator < ActiveModel::Validator
  def validate(record)
    if record.title.reject(&:empty?).empty?
      record.errors[:title] << "You must provide a title"
    end
  end
end
