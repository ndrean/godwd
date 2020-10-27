class Api::V1::SseEventsController < ActionController::Base
    include ActionController::Live

  def update_events
    response.headers['Content-Type'] = 'text/event-stream' # SSE expects the `text/event-stream` content type
    sse = SSE.new(response.stream, retry: 3000, event: "new") 
    last_updated_event = Event.last_updated  # method in the model
    logger.debug ".........UPDATE: last....#{last_updated_event}"

    # TRIAL WITH AFTER COMMIT: rendering pb ??
    # logger.debug ".........UPDATE: before..#{Event.updated_event}"
    # sse.write(Event.updated_event.to_json( include: [ 
    #         user: {only: [:email]},
    #         itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
    #         ]
    #     )) if Event.updated_event

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
      logger.debug "...........DEL....#{Event.deleted_id}"
      sse.write( {id: Event.deleted_id}.to_json) if Event.deleted_id
      # sse.Write( {id: Event.notify_delete}.to_json) if Event.notify_delete
    rescue IOError
    ensure
      sse.close
      # Event.deleted_id = nil
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
  
private
  def recently_changed?(event)
    event.created_at > 5.seconds.ago or
      event.updated_at > 5.seconds.ago
  end

end

