class RemoveDirectLink
  include Sidekiq::Worker
  #queue_as :default

    def perform(event_publicID)
      auth = {
        cloud_name: ENV['CL_CLOUD_NAME'],
        api_key: ENV['CL_API_KEY'],
        api_secret: ENV['CL_API_SECRET']
      }
      
      return if !event_publicID
      Cloudinary::Uploader.destroy(event_publicID, auth)
    end
end