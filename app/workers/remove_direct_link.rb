class RemoveDirectLink
  include Sidekiq::Worker
  queue_as :default

    def perform(event_publicID)
      return if !event_publicID
      Cloudinary::Uploader.destroy(event_publicID)
    end
end