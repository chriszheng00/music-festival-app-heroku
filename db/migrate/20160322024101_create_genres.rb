class CreateGenres < ActiveRecord::Migration
<<<<<<< HEAD

=======
>>>>>>> 3c009229f304f14407c20786d2b1626b90221819
  def change
    create_table :genres do |t|
      t.string :name
      t.timestamps null: false
    end

    create_table :festival_genres do |t|
      t.references :genre, index: true
      t.references :festival, index: true
      t.timestamps null: false
    end

    # SEED DB W/ FESTIVAL GENRES
  #   festival = FestivalService.new
  #   page = festival.get_festival_page
  #
  #   puts "Seeding genres..."
  #   # list of genres
  #   genres = page.css('#menu-item-15857 li').map do |genre|
  #     Genre.create(name: genre.text)
  #     genre.text
  #    end
  #
  #   urls = page.css('.gm-infowindow a:first-child').map { |link| link['href'] }
  #
  #   puts "Adding genres to festivals..."
  #   urls.each do |url|
  #     details = festival.get_the_body(url)
  #     # correct for some festivals having an extra space in their name
  #     festival_name = details.css('.entry-title span').text
  #
  #     info = details.css('.heading-meta-item a').children.map do |row|
  #       row.text
  #     end
  #
  #     info.each do |row|
  #       find_festival = Festival.find_by(name: festival_name)
  #       if genres.include?(row) && find_festival
  #         genre_id = Genre.find_by(name: row).id
  #         FestivalGenre.create(festival_id: find_festival.id, genre_id: genre_id)
  #       end
  #     end
  #   end
  #
  #   puts "Done! :)"
  end
end
