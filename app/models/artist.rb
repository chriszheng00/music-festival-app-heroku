class Artist < ActiveRecord::Base
  has_many :performances, dependent: :destroy
  has_many :festivals, through: :performances
  
  after_save :load_into_soulmate
  before_destroy :remove_from_soulmate

  def load_into_soulmate
    loader = Soulmate::Loader.new("artists")
    loader.add("term" => name, "id" => id)
  end

  def remove_from_soulmate
    loader = Soulmate::Loader.new("artists")
    loader.remove("id" => id)
  end
end
