class FestivalGenre < ActiveRecord::Base
  belongs_to :festival
  belongs_to :genre
end
