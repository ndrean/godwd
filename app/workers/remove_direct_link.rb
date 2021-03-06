# version with Sidekiq : no queue, just 'include Sidekiq' and use
# "RemoveDirectLink.perform_async" in controller

class RemoveDirectLink
  include Sidekiq::Worker
  sidekiq_options retry: false

    # 'perform' receives arguments from the 'perform_async' in the ctrler
    def perform(event_publicID)
      # secret credentials set maunually on each call
      auth = {
        cloud_name: Rails.application.credentials.CL[:CLOUD_NAME],
        api_key: Rails.application.credentials.CL[:API_KEY],
        api_secret: Rails.application.credentials.CL[:API_SECRET]
      }

      return if !event_publicID
      Cloudinary::Uploader.destroy(event_publicID, auth)
    end
end