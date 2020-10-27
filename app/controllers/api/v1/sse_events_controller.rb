class Api::V1::SseEventsController < ActionController::Base
    include ActionController::Live
    
  def update_events
    response.headers['Content-Type'] = 'text/event-stream' # SSE expects the `text/event-stream` content type
    sse = SSE.new(response.stream, retry: 1000) 
    if Event.updated_event
      logger.debug "...NEW...#{Event.updated_event}"
      sse.write(Event.updated_event.to_json(include: [ 
            user: {only: [:email]},
            itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
            ]), event: 'new') 
    end
    # last_updated_event = Event.last_updated  # method in the model
    # recent = recently_changed?(last_updated_event)
    # if recent # private method at the end
    #   logger.debug "...NEW...#{last_updated_event}"
    #   sse.write(last_updated_event.to_json( include: [ 
    #       user: {only: [:email]},
    #       itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
    #     ]
    #   ), event:'new') 
    # end
  rescue IOError
  ensure
    sse.close
    logger.debug "....CHECK....#{timer_update(Event.updated_event)}"
    Event.updated_event = nil if timer_update(Event.updated_event)
  end
    

# Event.where("created_at <= '#{5.seconds.ago}'")
  
  

  def delete_event
    begin
      response.headers['Content-Type'] = 'text/event-stream'
      sse = SSE.new(response.stream, retry: 1000, event: "delEvt")

      logger.debug ".........DEL EVT.....#{Event.deleted_id}"      
      sse.write( {id: Event.deleted_id}.to_json) if Event.deleted_id
      
    rescue IOError
    ensure
      Event.deleted_id = nil if timer_delete(Event.get_time_delete)
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
  
private
  # def recently_changed?(event)
  #   event.created_at > 5.seconds.ago or event.updated_at > 5.seconds.ago
  # end

  def timer_update(event)
    if (event)
      tc = DateTime.now.to_i - event.created_at.to_i
      tu = DateTime.now.to_i - event.updated_at.to_i
      [tu, tc].min > 4
    end
  end

  def timer_delete(time)
    if (time)
      (DateTime.now.to_i - time.to_i) > 5
    end
  end

  #  ArgumentError (comparison of Integer with ActiveSupport::TimeWithZone failed)
end

