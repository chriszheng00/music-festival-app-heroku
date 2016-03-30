# ORIGINAL SEED FILE IN CASE NEEDED
# TODO: refactor!
def extract_data
 page = get_the_body('https://www.musicfestivalwizard.com/music-festival-map')
 festival_info = []
 page.css('.marker').each do |marker|
   data = {}
   data[:lat] = marker.attributes["data-lat"].value
   data[:lng] = marker.attributes["data-lng"].value
   data[:city] = marker.css('p')[0].children.text
   data[:date] = marker.css('p')[1].children.text
   data[:start_date] = format_date(marker)
   data[:event] = get_event_name(marker)

   url = marker.children.css('.gm-infowindow a:first-child')[0]['href']
   details = get_the_body(url)
   festival = details.css('#festival-basics').children.select do |line|
       (line.name == 'text' || line.name == 'a') && !line.text.start_with?("\r\n")
     end

   data[:price] = festival[2].text if festival[2]
   data[:camping] = festival[3].text if festival[3]
   data[:website] = festival[4]['href'] if festival[4]
   data[:description] = festival[5].text if festival[5]
   data[:artists] = details.css('.lineupguide li').map { |artist| artist.text.capitalize if artist.text }

   festival_info << data
 end
 festival_info
end

def format_date(marker)
 date = marker.css('p')[1].children.text
 date_arr = date.gsub(/\-\w+/, '').gsub(',', '').split(' ')
 months = ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December']
 find_month = months.index(date_arr.shift)
 month_num = find_month ? find_month + 1 : 1
 Date.new(date_arr.last.to_i, month_num, date_arr.first.to_i)
end

def get_event_name(marker_obj)
  marker_obj.css('a:nth-child(2)')[0].children.text
end

#def to_nokogiri(body)
# Nokogiri::HTML(body)
#end

def get_the_body(url)
body = HTTParty.get(url)
Nokogiri::HTML(body)
end

extract_data.each do |i|
 f = Festival.create(
   name: i[:event],
   latitude: i[:lat].to_f,
   longitude: i[:lng].to_f,
   location: i[:city],
   start_date: i[:start_date],
   date: i[:date],
   website: i[:website],
   description: i[:description],
   price: i[:price],
   camping: i[:camping]
   )
 # here to reassure myself data is being saved to db
 puts f.name

 i[:artists].each do |artist|
   a = Artist.find_or_create_by(name: artist)
   Performance.create(artist_id: a.id, festival_id: f.id)
 end
end