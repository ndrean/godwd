class Api::V1::SseEventsController < ActionController::Base
    include ActionController::Live

  def update_events
      response.headers['Content-Type'] = 'text/event-stream' # SSE expects the `text/event-stream` content type
      sse = SSE.new(response.stream, retry: 500, event: "new")
      if Event.created_event
        sse.write(Event.created_event) 
        logger.debug "........UPDATE...#{JSON.parse(Event.created_event)['id'] }"
      end
      
      
    # last_updated_event = Event.last_updated  # method in the model
    # if recently_changed?(last_updated_event) # private method at the end
    #   logger.debug ".......UPDATE....#{last_updated_event.id}"
    #   sse.write(last_updated_event.to_json( include: [ 
    #         user: {only: [:email]},
    #         itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
    #         ]
    #     )) 
    # end
    # Event.created_event = nil
  rescue IOError
  ensure
    sse.close
    Event.created_event = nil
  end

# Event.where("created_at <= '#{5.seconds.ago}'")
  # Iodine.subscribe('delEvt') do |channel, data|
    #   logger.debug "............#{channel} :: #{data} "

    #   # sse.write( data, event: "delEvt") if data
    # end
  
  ### with class variable assigned in events_controller#destroy
  def delete_event
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 500, event: "delEvt")
    if Event.deleted_id
      sse.write( {id: Event.deleted_id}.to_json) 
      logger.debug ".......DEL........#{Event.deleted_id}"
    end
    
  rescue IOError
  ensure
    sse.close
    Event.deleted_id = nil
  end

  ## POSTGRES LISTEN NOTIFY
  # def psql_delete_event
  #   begin
  #     response.headers['Content-Type'] = 'text/event-stream'
  #     sse = SSE.new(response.stream, retry: 5000, event: 'psqlDel')
  #     Event.on_event_delete do |id|
  #       logger.debug "...........ID:..#{id}"
  #       sse.write({id: id}.to_json)
  #     end
  #   rescue ClientDisconnected
  #   ensure
  #     sse.close
  #   end
  # end
  
private
  def recently_changed?(event)
    event.created_at > 5.seconds.ago or
      event.updated_at > 5.seconds.ago
  end

end

