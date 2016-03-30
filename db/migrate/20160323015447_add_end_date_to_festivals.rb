class AddEndDateToFestivals < ActiveRecord::Migration
  def change 
    add_column :festivals, :end_date, :date
  end
end
