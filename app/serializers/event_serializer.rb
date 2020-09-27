class EventSerializer
  include FastJsonapi::ObjectSerializer
  attributes :user, :itinary
  belongs_to :user
  belongs_to :itinary

end
