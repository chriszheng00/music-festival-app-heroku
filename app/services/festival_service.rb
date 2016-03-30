class FestivalService
  def initialize
  end

  def get_the_body(url)
    body = HTTParty.get(url)
    Nokogiri::HTML(body)
  end

  def get_festival_page
    get_the_body('https://www.musicfestivalwizard.com/music-festival-map')
  end
end
