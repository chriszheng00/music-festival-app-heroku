class AddFestivals < ActiveRecord::Migration
  def change
    create_table :festivals do |t|
      t.string :name
      t.float :latitude
      t.float :longitude
      t.date :start_date
      t.string :date
      t.string :location
      t.string :website
      t.text :description
      t.integer :price
      t.string :camping
      t.timestamps null: false
    end

    create_table :artists do |t|
      t.string :name
      t.timestamps null: false
    end

    create_table :performances do |t|
      t.references :festival
      t.references :artist
      t.timestamps null: false
    end
  end
end
