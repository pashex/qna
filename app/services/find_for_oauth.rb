class Services::FindForOauth
  attr_reader :auth

  def initialize(auth)
    @auth = auth
  end

  def call
    authorization = Authorization.find_by(provider: auth.provider, uid: auth.uid)
    return authorization.user if authorization

    email = auth.info.email || ''
    user = User.find_by(email: email) if email.present?

    User.transaction do
      unless user
        password = Devise.friendly_token[0, 20]
        user = User.new(email: email, password: password, password_confirmation: password)
        if email.present?
          user.skip_confirmation!
          user.save!
        else
          user.save!(validate: false)
        end
      end

      user.authorizations.create!(provider: auth.provider, uid: auth.uid)
    end

    user
  end

end
