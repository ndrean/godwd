# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allowed_headers = %i(get post put patch delete options head)
  allow do
    origins "https://localhost:3000", "http://localhost:8080", "https://thedownwinder.com"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end

  # allow do
  #   origins "http://localhost:8080"
  #   resource "*",
  #     headers: :any,
  #     methods: [:get, :post, :put, :patch, :delete, :options, :head]
  # end

  # allow do
  #   origins "https://thedownwinder.com"
  #   resource "*",
  #     headers: :any,
  #     methods: [:get, :post, :put, :patch, :delete, :options, :head]
  # end

end
