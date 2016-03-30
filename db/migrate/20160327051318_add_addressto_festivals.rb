class AddAddresstoFestivals < ActiveRecord::Migration
  def change
    change_table :festivals do |t|
      t.string :city
      t.string :state
      t.string :country
    end
  end
end
