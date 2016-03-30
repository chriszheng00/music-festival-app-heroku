class FestivalsController < ApplicationController
  autocomplete :airport, :name, :full => true, :extra_data => [:iata_code]
  SEARCH_RADIUS = 500

  def show
    @festival = Festival.find(params[:id])
    fg = FestivalGridService.new
    @selected_festivals = fg.get_saved_festivals
    driving = DrivingInfoService.new(@festival)
    @price_by_car = driving.calc_driving_cost
    @time_by_car = driving.get_trip_time[0]
    @usr_location = $redis.hgetall('user')
  end

  def all
    @genres = Genre.all.order(:name)
    @usr_location = $redis.hget('user', 'location')
    @upcoming = Festival.includes(:genres).where('start_date > ?', Date.today).order(:start_date).limit(20)
    fg = FestivalGridService.new
    @selected_festivals = fg.get_saved_festivals
  end

  # PRE-CALCULATE COORDINATES FOR USER LOCATION
  def get_usr_info
    d = DistanceService.new
    d.get_usr_location(params[:usr_location])
    redirect_to root_path
  end

  # GET FESTIVAL SEARCH RESULTS
  def festival_list
    date = params[:date] == '' ? Date.today : params[:date]
    festivals = Festival.joins("INNER JOIN performances AS p ON p.festival_id = festivals.id INNER JOIN artists AS a ON p.artist_id = a.id INNER JOIN festival_genres AS fg ON fg.festival_id = festivals.id INNER JOIN genres AS g ON fg.genre_id = g.id").where('start_date >= ? AND LOWER(camping) LIKE ? AND g.name LIKE ? AND a.name LIKE ?', date, "%#{params[:camping]}%", "%#{params[:genre]}%", "%#{params[:artist]}%").distinct

    d = DistanceService.new
    origin = $redis.hgetall('user')
    @festivals = festivals.select do |f|
      dist_km = d.calc_distance(origin['lat'], origin['lng'], f)
      puts dist_km
      dist_km <= SEARCH_RADIUS
    end
    render json: @festivals
  end

  # TODO: refactor
  def festival_select
    festival = Festival.find(params[:festivalId])
    festival_json = festival.as_json
    user = $redis.hgetall('user')

    fg = FestivalGridService.new
    if flight_exists?(festival)
      flight = fg.get_cheapest_flight(festival, user)
      festival_json['price_flight'] = flight['PricingOptions'][0]['Price']
      festival_json['time_flight_in'] = flight[:inbound_leg]['Duration']
      festival_json['time_flight_out'] = flight[:outbound_leg]['Duration']
    end

    festival_json['price_car'] = params[:drivingPrice]

    festival_json['time_car'] = params[:drivingTime]
    bus = fg.get_first_bus(festival)
    festival_json['price_bus'] = bus[:cost]
    festival_json['time_bus'] = bus[:travel_time]

    if festival
      $redis.hset('festivals', festival.id, festival_json.to_json)
    end
    redirect_to root_path
  end
  
  def festival_unselect
    $redis.hdel('festivals', params[:festivalId])
    redirect_to root_path
  end

  def autocomplete
    input = params["query"]
    @results = Festival.autocomplete(input)
    @results = @results["airports"].to_json

    respond_to do |format|
      format.json { render json: @results }
    end
  end

  def flickr_images 
    festival = params[:festival].gsub(/\s\d{4}/, '')
    @festival = Festival.find_by(name: params[:festival])
  img_src = "https://api.flickr.com/services/rest/?api_key=#{ENV['FLICKR_KEY']}&method=flickr.photos.search&tags=festival&text=#{festival}&sort=relevance&per_page=10&page=1&content_type=1&format=json&nojsoncallback=1"
    response = HTTParty.get(img_src).body
    @image = JSON.parse(response)
    render json: @image
  end

  def parse_all
    render json: Festival.all, content_type: "application/json"
  end

  def search_flights
    @festival = Festival.find(params[:festival_id])
 
    if params[:default]
      params[:cabin_class] = "Economy"
      params[:adult] = 1
      params[:children] = 0
      params[:infants] = 0
      params[:departure_airport] = $redis.hget('user', 'departure_airport')

      d = DistanceService.new
      params[:arrival_airport] = d.get_nearest_airport(@festival.latitude, @festival.longitude, @festival.country)

    else
      params[:departure_airport] = Airport.find(params[:departure_airport_id])[:iata_code].downcase
      params[:arrival_airport] = Airport.find(params[:arrival_airport_id])[:iata_code].downcase
    end

    if flight_exists?(@festival)
      @first_five_results = @festival.search_flights(params)
    end

    @cabin_classes = [['Economy', 'Economy'], ['Premium Economy', 'PremiumEconomy'], ['Business', 'Business'], ['First Class', 'First']]
    @passenger_numbers = [['0', 0], [ '1', 1], ['2', 2], ['3', 3], ['4', 4], ['5', 5]]
 
    respond_to do |format|
      format.js {render layout: false}
    end
  end

  def search_greyhound
    # @depart_date = '2016-06-01'
    # @depart_from = {city: 'Vancouver', state: 'BC'}
    # @return_date = '2016-06-02'
    # @return_from = {city: 'Los Angeles', state: 'CA'}
    # @trip_type = "Round Trip"
    @festival = Festival.find(params[:festival_id])
    usr_location = $redis.hget('user', 'location').split(', ')
    @depart_date = (@festival.start_date - 1).strftime
    @depart_from = { city: usr_location[0], state: usr_location[1]}
    @return_date = (@festival.end_date + 1).strftime
    @return_from = { city: @festival.city, state: @festival.state }
    trip_type = "Round Trip"
    browser = "phantomjs"
    if @festival.country != "CA" && @festival.country != "US"
      @greyhound_data = "Sorry, bus schedules are currently only available for Canada and US"
    elsif @depart_from == @return_from
      @greyhound_data = "Festival is located in your home city. You're already there!"
    elsif Date.today > @festival.end_date
      @greyhound_data = "Festival has already ended. No greyhound bus schedules available."
    elsif Date.today >= @festival.start_date
      @greyhound_data = "Festival already in progress. No greyhound bus schedules available."
    else
      ghound = GreyhoundScraper.new(@depart_date, @depart_from, @return_date, @return_from, trip_type, browser)
      @greyhound_data = ghound.run

      # testing - test data
      # @greyhound_data = "some error"
      # @greyhound_data = {:depart=>{0=>{:cost=>"79.00", :start_time=>"12:15AM", :end_time=>"07:40AM", :travel_time=>"7h 25m"}, 1=>{:cost=>"79.00", :start_time=>"06:30AM", :end_time=>"12:15PM", :travel_time=>"5h 45m"}, 2=>{:cost=>"88.00", :start_time=>"12:30PM", :end_time=>"05:30PM", :travel_time=>"5h 00m"}, 3=>{:cost=>"81.00", :start_time=>"02:30PM", :end_time=>"07:30PM", :travel_time=>"5h 00m"}, 4=>{:cost=>"81.00", :start_time=>"06:00PM", :end_time=>"11:45PM", :travel_time=>"5h 45m"}}, :return=>{0=>{:cost=>"", :start_time=>"08:00AM", :end_time=>"01:20PM", :travel_time=>"5h 20m"}, 1=>{:cost=>"", :start_time=>"09:15AM", :end_time=>"04:40PM", :travel_time=>"7h 25m"}, 2=>{:cost=>"", :start_time=>"12:01PM", :end_time=>"05:00PM", :travel_time=>"4h 59m"}, 3=>{:cost=>"", :start_time=>"03:30PM", :end_time=>"09:30PM", :travel_time=>"6h 00m"}, 4=>{:cost=>"", :start_time=>"11:15PM", :end_time=>"05:05AM", :travel_time=>"5h 50m"}}}
    end

    respond_to do |format|
      format.js {render layout: false}
    end
  end

  
end
