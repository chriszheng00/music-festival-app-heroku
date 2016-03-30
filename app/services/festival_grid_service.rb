class FestivalGridService
  include Skyscanner

  def initialize
  end

  def get_saved_festivals
    $redis.hkeys('festivals').map do |key|
      JSON.parse($redis.hget('festivals', key))
    end
  end

  def get_cheapest_flight(festival, user)
    d = DistanceService.new
    flight_params = {
      departure_airport: user['airport'] || 'yvr',
      arrival_airport: d.get_nearest_airport(festival.latitude, festival.longitude, festival.country),
      festival_id: festival.id,
      cabin_class: 'Economy',
      adults: 1,
      children: 0,
      infants: 0
      }
    festival.search_flights(flight_params)[0]
  end
  
  # TODO: refactor  
  def get_first_bus(festival)
    usr_location = $redis.hget('user', 'location').split(', ')
    depart_date = (festival.start_date - 1).strftime
    depart_from = { city: usr_location[0], state: usr_location[1] }
    return_date = (festival.end_date + 1).strftime
    return_from = { city: festival.city, state: festival.state }

    if festival.country != "CA" && festival.country != "US"
      @data = "Sorry, bus schedules are currently only available for Canada and US"
    elsif depart_from == return_from
      @data = "Festival is located in your home city. You're already there!"
    elsif Date.today > festival.end_date
      @data = "Festival has already ended. No greyhound bus schedules available."
    elsif Date.today >= festival.start_date
      @data = "Festival already in progress. No greyhound bus schedules available."
    else
      g = GreyhoundScraper.new(depart_date, depart_from, return_date, return_from, 'Round Trip', 'phantomjs')
      @data = g.run_depart
    end
    @data
  end
end
