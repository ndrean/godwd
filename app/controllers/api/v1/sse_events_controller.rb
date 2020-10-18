# class EventstreamChannel < ApplicationCable::Channel

  # def subscribed
  #   stream_from events_channel
  # end

  # def received(data)
  #   EventsstreamChannel.broadcast_to(
  #     events_channel, {
  #       room:events_channel,
  #       users: events_channel.users,
  #       messages: events_channel.messages
  #   })
  # end

  # def unsubscribed
  # # Any cleanup needed when channel is unsubscribed
  #   raise NotImplementedError
  # end

class Api::V1::SseEventsController < ActionController::Base
    include ActionController::Live

def update_events
  sse = SSE.new(response.stream, retry: 5000, event: "new") 
  response.headers['Content-Type'] = 'text/event-stream'
  # SSE expects the `text/event-stream` content type
  last_updated_event = Event.last_updated  
  if recently_changed?(last_updated_event)
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

# def redis_delete_event
#   redis = Redis.new(url: "redis://127.0.0.1", port: '6379') #url: ENV.fetch("REDIS_URL"))
#   response.headers['Content-Type'] = 'text/event-stream'
#   sse = SSE.new(response.stream, retry: 5000, event: 'delete_event')
#   ticker = Thread.new { loop { sse.write 0; sleep 5 } }
#   sender = Thread.new do
#     redis.psubscribe('delete_event') do |on|
#       on.message do |channel, data| 
#         response.stream.write(data) 
#       end
#     end
#   end
#   ticker.join
#   sender.join
#   # redis.unsubscribe('delete_event')
# rescue IOError
# ensure
#   Thread.kill(ticker) if ticker
#   Thread.kill(sender) if sender
#   redis.close
#   response.stream.close
# end


def delete_event
  sse = SSE.new(response.stream, event: "delEvt") 
  response.headers['Content-Type'] = 'text/event-stream'
  # Event.where("created_at <= '#{5.seconds.ago}'")
  if Event.deleted_id
    logger.debug "..........Class: #{Event.deleted_id}"
    sse.write({id: Event.deleted_id}.to_json)
  end
rescue IOError
ensure
  sse.close
end
  
private
  def recently_changed?(event)
    event.created_at > 5.seconds.ago or
      event.updated_at > 5.seconds.ago
  end

end

