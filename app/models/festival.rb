class Festival < ActiveRecord::Base
  include Skyscanner

  has_many :performances, dependent: :destroy
  has_many :artists, through: :performances
  has_many :festival_genres, dependent: :destroy
  has_many :genres, through: :festival_genres

  validates :name, presence: true

  def search_flights(params)
    session_id = create_skyscanner_session(params)
    data = get_itineraries(session_id)
    @results = get_first_five_results(data)
    return @results
  end

  def airport(latitude, longitude)
    arrival_airport = nearest_airport(latitude, longitude)
    arrival_airport = arrival_airport["airports"][0]["code"]

    return arrival_airport
  end

  def self.different_airport?(departure, arrival)
    departure != arrival
  end

end
  
