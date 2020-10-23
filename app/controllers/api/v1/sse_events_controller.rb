class Api::V1::SseEventsController < ActionController::Base
    include ActionController::Live

  def update_events
    response.headers['Content-Type'] = 'text/event-stream' # SSE expects the `text/event-stream` content type
    sse = SSE.new(response.stream, retry: 3000, event: "new") 
    last_updated_event = Event.last_updated  # method in the model
    if recently_changed?(last_updated_event) # private method at the end
      sse.write(last_updated_event.to_json( include: [ 
            user: {only: [:email]},
            itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
            ]
        )) 
    end
  rescue IOError
  ensure
    sse.close
  end

# Event.where("created_at <= '#{5.seconds.ago}'")
  
  

  def delete_event
    begin
      response.headers['Content-Type'] = 'text/event-stream'
      sse = SSE.new(response.stream, retry: 1000, event: "delEvt")
      
      begin
        Event.on_event_delete do |id|
          logger.debug "...........ID:..#{id}"
        end
      rescue ClientDisconnected
      end

      if Event.deleted_id
        logger.debug "..........Class: #{Event.deleted_id}"
        sse.write( {id: Event.deleted_id}.to_json)
      end
    rescue IOError
    ensure
      sse.close
    end
  end

  ## POSTGRES LISTEN NOTIFY
  # def delete_event
  #   begin
  #     Event.on_event_delete do |id|
  #       logger.debug "...........ID:..#{id}"
  #     end
  #   rescue ClientDisconnected
      
  #   end
  # end

  ## REDIS PUBLISH SUBSCRIBE
  # def redis_delete_event
  #   begin
  #     response.headers['Content-Type'] = 'text/event-stream'
  #     sse = SSE.new(response.stream, retry: 5000, event: 'delete_event')
  #     redis = Redis.new(url: ENV.fetch('REDIS_URL')) #url: ENV.fetch("REDIS_URL"))
  #     logger.debug "..............#{redis.ping}"
  #     # ticker = Thread.new { loop { sse.write 0; sleep 5 } }
  #     # sender = Thread.new do
  #     redis.subscribe('delete_event') do |on|
  #       on.message do |channel, data| 
  #         logger.info "............#{channel}:: #{data}"
  #         sse.write(data) 
  #       end
  #     end
  #     # end
  #     # ticker.join
  #     # sender.join
  #     # redis.unsubscribe('delete_event')
  #   rescue IOError
  #   ensure
  #     # Thread.kill(ticker) if ticker
  #     # Thread.kill(sender) if sender
  #     # redis.close
  #     sse.close
  #   end
  # end
  
private
  def recently_changed?(event)
    event.created_at > 5.seconds.ago or
      event.updated_at > 5.seconds.ago
  end

end

