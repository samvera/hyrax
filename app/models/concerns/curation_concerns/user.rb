module CurationConcerns::User
  extend ActiveSupport::Concern
  included do
    delegate :can?, :cannot?, to: :ability
  end

  # Redefine this for more intuitive keys in Redis
  def to_param
    # HACK: because rails doesn't like periods in urls.
    user_key.gsub(/\./, '-dot-')
  end

  private

    def ability
      @ability ||= ::Ability.new(self)
    end
end
