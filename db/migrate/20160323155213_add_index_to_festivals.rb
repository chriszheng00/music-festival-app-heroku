class AddIndexToFestivals < ActiveRecord::Migration
  def change
    add_index :festivals, :start_date
    add_index :festivals, :camping
    add_index :performances, :festival_id
    add_index :performances, :artist_id
  end
end
