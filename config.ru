# This file is used by Rack-based servers to start the application.
require 'rack'
require 'rack/brotli'
require_relative 'config/environment'

# use Rack::Brotli
run Rails.application
