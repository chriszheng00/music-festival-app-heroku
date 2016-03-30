class CreateAirports < ActiveRecord::Migration
  def change
    create_table :airports do |t|
      t.string :name
      t.float :latitude
      t.string :longitude
      t.string :float
      t.string :city
      t.string :country
      t.string :iata_code

      t.timestamps null: false
    end
  end
end
