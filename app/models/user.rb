class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable,
         :omniauthable, :omniauth_providers => [:instagram]

  has_many :subjects

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.access_token = auth.credentials.token
      user.image = auth.info.image
    end
  end

  def self.find_by_uid(uid)
    where({uid:uid}).first
  end

  def exceeded_follow_limit?
    total_follows >= total_allowed_follows
  end

  def password_required?
    false
  end
end
