class Event < ApplicationRecord
  belongs_to :user
  belongs_to :itinary
  accepts_nested_attributes_for :itinary
  
  cattr_accessor :deleted_id

  scope :last_updated, -> {
    joins(:user,:itinary)
    .order('updated_at DESC, created_at DESC')
    .first
  }

  # def self.publish_delete(channel, id)
    # connection =  ActiveRecord::Base.connection
    # connection.execute("LISTEN C#{channel}")

    # redis = Redis.new(url: ENV.fetch('REDIS_URL')) #url: ENV.fetch("REDIS_URL"))
    # redis.publish("delete_event", {id: id}.to_json)
  # end

  def self.set_id(id)
    Event.deleted_id = id
  end

end
