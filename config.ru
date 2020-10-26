# This file is used by Rack-based servers to start the application.
require 'rack'
#require 'rack/brotli'
require_relative 'config/environment'

# The Rack DSL used to run the application
# run APP

run Rails.application
