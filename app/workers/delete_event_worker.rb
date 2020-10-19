# version with Sidekiq : no queue, just 'include Sidekiq' and use
# "RemoveDirectLink.perform_async" in controller

class DeleteEventWorker
  # include Sidekiq::Worker
  # sidekiq_options retry: false

  #   # 'perform' receives arguments from the 'perform_async' in the ctrler
  #   def perform(id)
  #     Event.publish_delete(id)
  #   end
end