class Event < ApplicationRecord
  belongs_to :user
  belongs_to :itinary
  accepts_nested_attributes_for :itinary
  
  after_commit :publish_delete, on: :destroy
  after_commit :publish_create, on: [:create,:update]
  
  cattr_accessor :deleted_id
  cattr_accessor :created_event
  
  scope :last_updated, -> {
    joins(:user,:itinary)
    .order('updated_at DESC, created_at DESC')
    .first
  }

  ### with class variable
  def self.set_id(id)
    Event.deleted_id = id
  end

  def publish_delete
    Event.deleted_id = self.id
  end
  
  def publish_create
    Event.created_event = self.to_json( include: [ 
        user: {only: [:email]},
        itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
        ]
      )
  end
  # def publish_create
  #   Iodine.publish('createEvt', 
  #     self.to_json( include: [ 
  #           user: {only: [:email]},
  #           itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
  #           ]
  #       ), $redis
  #   )
  # end

  # def publish_delete
  #   Iodine.publish('delEvt', {id: self.id}.to_json, $redis)
  # end
  
  ### with Postgres NOTIFY
  # def notify_delete
  #   ActiveRecord::Base.connection_pool.with_connection do |connection|
  #     self.class.execute_query(connection, ["NOTIFY event_destroy, '?'", id])
  #   end
  # end

  # # postgres LISTEN
  # def self.on_event_delete
  #   ActiveRecord::Base.connection_pool.with_connection do |connection|
  #     begin
  #       # puts ActiveRecord::Base.connection_pool.instance_variable_get(:@thread_cached_conns).keys.map(&:object_id)
  #       execute_query(connection, ["LISTEN event_destroy"])
  #       connection.raw_connection.wait_for_notify do |event, pid, id|
  #         logger.debug "..............#{event} #{id}"
  #         yield id
  #       end
  #     ensure
  #       execute_query(connection, ["UNLISTEN event_destroy"])
  #     end
  #   end
  # end

  # def self.clean_sql(query)
  #   sanitize_sql(query)
  # end

  # def self.execute_query(connection, query)
  #   sql = self.clean_sql(query)
  #   connection.execute(sql)
  # end


  

end
