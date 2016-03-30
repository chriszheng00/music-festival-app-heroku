module FestivalHelper
  def display(info)
    info.nil? || info == 0 ? 'n/a' : info
  end
  
  def get_genres(festival)
    genres_lst = festival.genres.map do |genre|
      genre.name
    end
    genres = genres_lst.join(', ')
    content_tag(:span, genres)
  end
end
