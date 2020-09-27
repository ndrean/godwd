class UserSerializer
  include FastJsonapi::ObjectSerializer
  attributes :email
  has_many :events
end
