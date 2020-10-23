class Event < ApplicationRecord
  belongs_to :user
  belongs_to :itinary
  accepts_nested_attributes_for :itinary
  
  # before_commit :notify_delete, on: :destroy

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
