class PlacesController < ApplicationController
  def index
  end

  def show
    #this retrieves all things at this place and returns them as json to the client
    @place = Place.search(self.params[:id]).first
    @place = Place.create(:guid=>self.params[:id]) unless @place
    render :json=>@place.things.to_json
  end
end
