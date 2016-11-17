module CurationConcerns::User
  extend ActiveSupport::Concern
  included do
    delegate :can?, :cannot?, to: :ability
    has_one :sipity_agent, as: :proxy_for, dependent: :destroy, class_name: 'Sipity::Agent'
  end

  # Redefine this for more intuitive keys in Redis
  def to_param
    # HACK: because rails doesn't like periods in urls.
    user_key.gsub(/\./, '-dot-')
  end

  def to_sipity_agent
    sipity_agent || create_sipity_agent!
  end

  private

    def ability
      @ability ||= ::Ability.new(self)
    end
end
