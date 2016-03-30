class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def flight_exists?(festival)
    @valid_search = Festival.different_airport?(params[:departure_airport], params[:arrival_airport])
    @in_future = festival.start_date > Time.now

    @valid_search && @in_future
  end
end
