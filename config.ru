require 'rubygems'
require 'bundler'
Bundler.require(:default)

require './api'
require './web'

# complie CoffeeScript to JS
use Rack::Coffee, root: 'public', urls: '/js'

use Rack::Session::Cookie
run Rack::Cascade.new [API, Web]
