class RemoveDirectLink
  include Sidekiq::Worker
  #queue_as :default

    def perform(event_publicID)
      auth = {
        cloud_name: Rails.application.credentials.CL[:CLOUD_NAME],
        api_key: Rails.application.credentials.CL[:API_KEY],
        api_secret: Rails.application.credentials.CL[:API_SECRET]
      }

      return if !event_publicID
      Cloudinary::Uploader.destroy(event_publicID, auth)
    end
end