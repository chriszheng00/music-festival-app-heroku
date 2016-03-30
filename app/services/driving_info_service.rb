class DrivingInfoService
  # right now this doesn't account for ferry prices/changing mode of transportation
  # TODO: driving distance within same city doesn't currently work [because based on city's latitude/longitude rather than specific addresses]
  attr_reader :origin

  def initialize(festival)
    @festival = festival
    @origin = $redis.hgetall('user')
  end

  def get_fuel_consumption
    fuel_csv = 'http://www.rncan.gc.ca/sites/www.rncan.gc.ca/files/oee/files/csv/MY2011%20Fuel%20Consumption%20Ratings%205-cycle.csv'
    cars = CSV.new(open(fuel_csv))
    all_cars = cars.select { |car| !car[-3].nil? }
    sum_all_cars = all_cars.reduce(0) do |sum, car|
      sum + car[-3].to_f
    end
    # default unit is L/100km
    sum_all_cars / all_cars.length
  end

  def get_avg_gas_price
    origin = @origin['location'].gsub(',','').split(' ').join('%2C')
    gasbuddy = Nokogiri::HTML(open("http://gasbuddy.com/?search=#{origin}"))
    gasbuddy.css('.gb-price-lg')[0].text.gsub(/\s+/, '').to_f / 100
  end

  def get_trip
    origin = [@origin['lat'], @origin['lng']].join(',')
    dest = [@festival.latitude, @festival.longitude].join(',')

    url  = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{origin}|#{dest}&destinations=#{dest}|#{origin}&key=#{ENV['GOOGL_DIST_KEY']}&avoid=tolls"
    encode_url = URI.encode(url)
    googl_dist = URI.parse(encode_url) 

    googl_resp = HTTParty.get(googl_dist, verify: false)
    googl_data = JSON.parse(googl_resp.body)['rows']

    round_trip = []
    googl_data.each do |trip|
      # filter the distance matrix
      trip['elements'].each do |ele|
        if ele['status'] == 'ZERO_RESULTS'
          round_trip << {'distance' => {'value' => 0}, 'duration' => {'text' => "n/a"}}
        elsif ele['distance']['value'] != 0
          round_trip << ele
        end
      end
    end
    round_trip
  end

  def get_trip_dist
    # convert from m to km & add distance to & from destination
    get_trip.reduce(0) do |sum, dist|
      dist_in_km = dist['distance']['value'] / 1000.0
      sum + dist_in_km
    end
  end

  def get_trip_time
    get_trip.map do |trip|
      trip['duration']['text']
    end
  end

  def calc_driving_cost
    # use trip distance as a multiplier for fuel consumption
    litres_needed = get_fuel_consumption * ( get_trip_dist / 100 )
    ( litres_needed * get_avg_gas_price ).round(2)
  end
end