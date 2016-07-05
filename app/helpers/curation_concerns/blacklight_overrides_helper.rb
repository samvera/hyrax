module CurationConcerns::BlacklightOverridesHelper
  # Overrides Blacklight::BlacklightHelperBehavior
  def presenter(document)
    case action_name
    when 'edit', 'update'
      show_presenter(document)
    else
      super(document)
    end
  end
end
