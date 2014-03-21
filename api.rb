require 'grape'
require 'json'

class API < Grape::API
  format :json


  # load data
  @@weights   = JSON.parse File.read('./data/weights.json')
  @@prices    = JSON.parse File.read('./data/prices_for_subsectors.json')
  @@sectorMap = JSON.parse File.read('./data/SubsectorToSectorMap.json')

  #
  get "/sector/:sector/prices" do
    @@prices[CGI::unescape(params[:sector])] or { error: 'Sector not found.' }
  end

  #
  get :sector_map do
    @@sectorMap
  end

  #
  get :weights do
    @@weights
  end


end
