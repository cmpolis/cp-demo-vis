class Web < Sinatra::Base

  #
  get '/' do
    haml :index
  end

  #
  get '/sector/:sector' do
    haml :sector
  end

end
