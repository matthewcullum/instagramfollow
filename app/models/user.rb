class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable,
         :omniauthable, :omniauth_providers => [:instagram]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.oauth_token = auth.credentials.token
      user.image = auth.info.image
    end
  end

  def self.find_by_uid(uid)
    where({uid:uid}).first
  end

  def password_required?
    false
  end
end
