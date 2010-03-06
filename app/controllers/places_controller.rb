class PlacesController < ApplicationController
  def index
  end

  def show
    #this retrieves all things at this place and returns them as json to the client
    @place = Place.find_or_create_by_guid(self.params[:id])
    render :nothing=>true
  end

  def ask
    email = Place.find_by_guid(self.params[:guid]).email
    if email
      PlaceMailer.deliver_question(self.params[:question],email)
      response='OK'
    else
      response='no email'
    end
    render :json=>response.to_json
  end

end
