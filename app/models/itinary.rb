class Itinary < ApplicationRecord
    has_many :events, dependent: :destroy
    
    validates :date, presence: true
    validates :start, presence: true
    validates :end, presence: true
end
