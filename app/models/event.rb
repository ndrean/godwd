class Event < ApplicationRecord
  belongs_to :user
  belongs_to :itinary
  accepts_nested_attributes_for :itinary
  
  before_commit :notify_delete, on: :destroy
  after_save :publish_event #, on: [:create, :update]

  cattr_accessor :deleted_id
  cattr_accessor :updated_event
  # cattr_accessor :deleted_event
  cattr_accessor :get_time_delete
  cattr_accessor :get_time_new

  scope :last_updated, -> {
    joins(:user,:itinary)
    .order('updated_at DESC, created_at DESC')
    .first
  }


  def self.set_id(id)
    Event.deleted_id = id
  end

  def notify_delete
    # Event.deleted_event = self 
    Event.deleted_id = self.id
    Event.get_time_delete = Time.now
  end

  def publish_event
    Event.updated_event = self
    Event.get_time_new = Time.now
  end

end
