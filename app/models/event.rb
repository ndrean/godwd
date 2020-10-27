class Event < ApplicationRecord
  belongs_to :user
  belongs_to :itinary
  accepts_nested_attributes_for :itinary
  
  before_commit :notify_delete, on: :destroy
  # after_commit :publish_update, on: [:create, :update]

  cattr_accessor :deleted_id
  cattr_accessor :updated_event

  scope :last_updated, -> {
    joins(:user,:itinary)
    .order('updated_at DESC, created_at DESC')
    .first
  }

  def self.set_id(id)
    Event.deleted_id = id
    # ActionCable.server.broadcast( "delEvt", {id: id}.as_json) ###################
  end

  def notify_delete
    Event.deleted_id = self.id
  end

  # def publish_update
  #   Event.updated_event = self
  # end

  # def recently_changed?(event)
  #   event.created_at > 5.seconds.ago or
  #     event.updated_at > 5.seconds.ago
  # end

  # def publish_update
  #   last_updated_event = Event.last_updated  # scope
  #   if recently_changed?(last_updated_event)
  #     ActionCable.server.broadcast(last_update_event.as_json( include: [ 
  #           user: {only: [:email]},
  #           itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
  #           ]
  #       )
  #     ) 
  #   end
  # end
  ############################


  

  # def self.clean_sql(query)
  #   sanitize_sql(query)
  # end

  # def self.execute_query(connection, query)
  #   sql = self.clean_sql(query)
  #   connection.execute(sql)
  # end
  
  # def notify_delete
  #   ActiveRecord::Base.connection_pool.with_connection do |connection|
  #     self.class;execute_query(connection, ["NOTIFY event_destroy, '?'", id])
  #   end
  # end

  # def self.on_event_delete
  #   ActiveRecord::Base.connection_pool.with_connection do |connection|
  #     begin
  #       puts ActiveRecord::Base.connection_pool.instance_variable_get(:@thread_cached_conns).keys.map(&:object_id)
  #       execute_query(connection, ["LISTEN event_destroy"])
  #       loop do
  #         connection.raw_connection.wait_for_notify do |event, pid, id|
  #           yield id
  #         end
  #       end
  #     ensure
  #       execute_query(connection, ["UNLISTEN event_destroy"])
  #     end
  #   end
  # end


end
