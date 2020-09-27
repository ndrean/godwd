class ItinarySerializer
  include FastJsonapi::ObjectSerializer
  attributes :date, :start, :end, :distance, :start_gps, :end_gps
  has_many :events
end
