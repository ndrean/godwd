class User < ApplicationRecord
    has_secure_password

    has_many :events, dependent: :destroy
    
    validates :email, uniqueness: true, presence: true
    validates :password_digest, presence: true

    validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    # modify token payload to accept uid given by Facebook
    def to_token_payload
        return { 
            sub: uid,
            email: email
         }
    end
end
