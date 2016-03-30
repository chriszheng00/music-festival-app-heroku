for i in 0..5

  festival = Festival.find(i)

  date = festival.date

  if date.count('-') == 1

    date = date.split("-")

    if date[1].start_with?(' ')

      month = date[1].squish.split(' ')[0]
      year = date[1].split(' ')[2]
      date = date[1].split(' ')[1].delete!(',')
    
    else

      month = date[0].split(' ')[0]

      date = date[1].split(',')

      year = date[1]

      date = date[0]

    end

      festival.end_date = Date.parse("#{month} #{date},#{year}")

      # festival.save

      puts festival.end_date

  
  elsif date.count('-') == 0

    festival.end_date = festival.start_date
    # festival.save

    puts festival.end_date
    
  end


end