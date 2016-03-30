# Scrapes Greyhound Site for trip cost.
# Watir depends on Selenium Webdriver
# Date must be in 'yyyy-mm-dd' format.

# Example:
# depart_date = '2016-06-01'
# depart_from = {city: 'Vancouver', state: 'BC'}
# return_date = '2016-06-02'
# return_from = {city: 'Los Angeles', state: 'CA'}
# trip_type = "Round Trip"
# ghound = GreyhoundScraper.new(depart_date, depart_from, return_date, return_from, trip_type)
# puts ghound.run

# For Chrome: chromedriver has been placed in /usr/local/bin/, will be auto detected by Selenium
# Todo - research headless scraping using PhantomJS

class GreyhoundScraper
  FORM_URL = 'https://mobile.greyhound.ca/tix1.html'
  attr_reader :depart_date
  attr_reader :depart_from
  attr_reader :return_date
  attr_reader :return_from
  attr_reader :trip_type

  def initialize(depart_date, depart_from, return_date, return_from, trip_type, browser_type)
    if browser_type.downcase == "chrome"
      @browser = Watir::Browser.new:chrome
    # @browser = Watir::Browser.start "www.google.com", :chrome   #alt
    elsif browser_type.downcase == "firefox"
      Selenium::WebDriver::Firefox::Binary.path='/Applications/Firefox.app/Contents/MacOS/firefox'
      @browser = Watir::Browser.new:firefox
    else  # assume phantomjs
      @browser = Watir::Browser.new:phantomjs, :args => ['--ignore-ssl-errors=true']
    end
    @depart_date = depart_date
    @depart_from = depart_from
    @return_date = return_date
    @return_from = return_from
    @trip_type = trip_type
    @browser_type = browser_type
  end

  def validate_depart_date
    if @depart_date > (Date.today + 322)
      'Departure date must not exeed ' + (Date.today + 322).to_s + '.'
    elsif @depart_date < Date.today
      'Departure date must be today (' + Date.today.to_s + ') or later.'
    else
      true
    end
  end

  def validate_return_date
    if @return_date > (Date.today + 322)
      'Return date must not exeed ' + (Date.today + 322).to_s + '.'
    elsif @return_date <= @depart_date
      'Return date must be be later than departure date(' + @depart_date.to_s + ')'
    else
      true
    end
  end

  # Todo - return success/fail msg
  def sure_load_link(mytimeout)
    browser_loaded = 0
    while (browser_loaded == 0)
      begin
      browser_loaded = 1
      Timeout::timeout(mytimeout) do
        yield
      end
      rescue Timeout::Error => e
        puts "Page load timed out: #{e}"
        browser_loaded = 0
        retry
      end
    end
    puts "Homepage Successfully loaded"
  end

  def try_action(msg, wait_time, tries)
    fails = 0
    begin
      yield
    rescue
      fails += 1
      puts "#{msg}: fail #{fails}"
      sleep wait_time
      fails < tries ? retry : (puts "#{msg}: gave up"; return "Error")
    end
    return "#{msg}: action success"
  end

  # Todo - Dry this, make it call try_action
  def try_click(msg)
    fails = 0
    begin
      yield
    rescue
      fails += 1
      puts "  #{msg}: fail #{fails}"
      sleep 0.2
      fails < 5 ? retry : (puts "  #{msg}: gave up"; return "Error")
    end
    return "  #{msg}: click success"
  end


  def open_browser
    # 5 seconds safe for Chrome, 7 seconds safe for phantomjs. Todo - conditional logic
    if @browser_type == "chrome"
      wait = 5
    elsif @browser_type == "firefox"
      wait = 7
    else
      wait = 7
    end
      sure_load_link(wait) { @browser.goto(FORM_URL) }
  end

  def enter_trip_type
    if @trip_type == "One Way"
      return try_click("Select One Way") { @browser.span(text: 'One Way').when_present.click }
    else
      return try_click("Select Round Trip") { @browser.span(text: 'Round Trip').when_present.click }
    end
    sleep 0.3
  end

  # placeholder must be "Leaving from..." or "Going to..."
  def enter_location(placeholder, location)
    puts try_click("Select #{placeholder}") { @browser.text_field(placeholder: placeholder).click }
    sleep 0.2
    @browser.text_field(placeholder: placeholder).set(location[:city][0..3])
    seg2 = location[:city][4..(location[:city].length - 1)]
    if seg2
      sleep 0.2
      @browser.text_field(placeholder: placeholder).append(seg2)
    end

    index = 0
    begin
      @browser.li(class: "ui-li ui-li-static ui-btn-up-x", index: index).wait_until_present(1)
    rescue Watir::Wait::TimeoutError => e
      return "Error"  # todo - make nicer
    end

    # put 'ui-li ui-li-static ui-btn-up-x' this in scrapper config file along with the url
    while (@browser.li(class: "ui-li ui-li-static ui-btn-up-x", index: index).exists?)
      dropdown_match = (location[:city] + ', ' + location[:state]).upcase
      if @browser.li(class: "ui-li ui-li-static ui-btn-up-x", index: index).text == dropdown_match
        puts try_click("Click dropdown #{dropdown_match}") { @browser.li(class: "ui-li ui-li-static ui-btn-up-x", index: index).click }
        puts "Found " + location[:city] + ', ' + location[:state]
        sleep 0.3
        return true   # happy path ends here
      end
      index += 1
    end
    puts "Error: " + location[:city] + ', ' + location[:state] + " not found"
    return "Error"
  end

  def enter_origin
    enter_location("Leaving from...", @depart_from)
  end

  def enter_destination
    enter_location("Going to...", @return_from)
  end


  # input_id must be "depart" or "return"
  def enter_date(input_id, date) 
    date_field = @browser.input(id: input_id) # try to inject into date field
    js_change_date = "return arguments[0].value = '#{date}'"   # not sure how arguments works, todo figure it out
    @browser.execute_script(js_change_date, date_field)
    sleep 0.1
  end

  def enter_depart_date
    enter_date("depart", @depart_date)
  end

  def enter_return_date
    enter_date("return", @return_date)
  end

  def submit_form(next_page)
    @browser.scroll.to :bottom if @browser_type != "phantomjs"
    puts try_click("Click 'View Schedules' to goto #{next_page}") { @browser.button.when_present.click }
    # Watir::Wait.until(6, "Couldn't load next page: " + next_page) { @browser.url.include? next_page }
    begin
      Watir::Wait.until(6) { @browser.url.include? next_page }
    rescue Watir::Wait::TimeoutError => e
      return "Error"  # todo - make nicer
    end
  end

  def submit_page1
    submit_form("tix2.html")
  end

  def submit_page2
    puts try_click("Select the first schedule in p2") { @browser.label(index: 0).when_present.click }
    sleep 0.2
    submit_form("tix3.html")
  end

  # check page status i -   if @browser.url.include? "mobile.greyhound.ca/tix2.html"
  def errors?
    if @browser.url.include? "tix1.html"
      if @browser.span(class: "feedbackPanelERROR").exists?
      #   if @browser.span(class: "feedbackPanelERROR").text.include? "No schedules"   #todo - necessary?
      #     return "No schedules found"
      # # elsif (todo - test for other error types)
      #   end
        return "No schedules found"
      end
    elsif @browser.url.include? "tix2.html"
      if @browser.p(class: "ui-li-aside", index: 0).span.exists? == false
        return "Couldn't get tickets"
      end
    end
  end

  # def get_costs
  #   costs = []
  #   i = 0
  #   while (@browser.p(class: "ui-li-aside", index: i).span.exists?)
  #     cost = @browser.p(class: "ui-li-aside", index: i).span.text
  #     cost[0] = '' if cost[0] = '$'
  #     costs << cost.to_f
  #     i += 1
  #   end
  #   costs_min_max = [costs.min, costs.max]
  #   return costs_min_max
  # end

  # helper for get_depart_data, get_return_data
  # 2 possibilities for type: depart, return
  def get_trip_data
    data = {}
    # for each departure/return entry, grab: start_time, end_time, travel_time, cost
    i = 0
    try_action("Wait for #{@browser.url} to load", 0.2, 10) { @browser.label(index: i).exists? } == "Error" ? (return "Error") : (puts "#{@browser.url} finished loading")
    sleep 0.2
    while (@browser.label(index: i).exists?)
      cost = @browser.label(index: i).p(class: "ui-li-aside").span.text
      cost[0] = '' if cost[0] = '$'   # remove $ sign
      start_time = @browser.label(index: i).h4.span.text
      end_time = @browser.label(index: i).p(index: 1).span(index: 1).text
      travel_time = @browser.label(index: i).p(index: 1).span(index: 3).text

      data[i] = { cost: cost, start_time: start_time, end_time: end_time, travel_time: travel_time}
      i += 1
    end
    puts "Found #{i} schedules"
    data
  end

  def close_browser
    # sleep 1   # testing
    @browser.close
  end

  def run
    self.open_browser
    puts self.enter_trip_type

    self.enter_origin == "Error" ? (puts "Error - Couldn't find origin"; @browser.close; return "No schedules available.") : (puts "Found origin")
    self.enter_destination == "Error" ? (puts "Error - Couldn't find destination"; @browser.close; return "No schedules available.") : (puts "Found destination")

    self.enter_depart_date  # assume error free
    self.enter_return_date  # assume error free
    self.submit_page1 == "Error" ? (puts "Error - Couldnt submit form"; @browser.close; return "No greyhound bus schedules available.") : (puts "Form submitted successfully")

    result = {}             # should be error free after this point
    result[:depart] = self.get_trip_data
    self.submit_page2 == "Error" ? (puts "Error - Couldnt submit form"; @browser.close; return "No greyhound bus schedules available.") : (puts "Form submitted successfully")
    result[:return] = self.get_trip_data

    # errors = self.errors?
    # if errors != nil
    #   result = errors
    # else
    #   result = {}
    #   result[:depart] = self.get_trip_data
    #   self.submit_page2
    #   result[:return] = self.get_trip_data
    # end

    self.close_browser
    result
  end

  # FOR CACHING
  def get_depart_data
    try_action("Wait for #{@browser.url} to load", 0.2, 10) { @browser.label(index: 0).exists? } == "Error" ? (return "Error") : (puts "#{@browser.url} finished loading")
    sleep 0.2
    cost = @browser.label(index: 0).p(class: "ui-li-aside").span.text
    cost[0] = '' if cost[0] = '$'
    travel_time = @browser.label(index: 0).p(index: 1).span(index: 3).text

    { cost: cost, travel_time: travel_time }
  end

  def run_depart
    open_browser
    puts enter_trip_type

    enter_origin == "Error" ? (puts "Error - Couldn't find origin"; @browser.close; return "No schedules available.") : (puts "Found origin")
    enter_destination == "Error" ? (puts "Error - Couldn't find destination"; @browser.close; return "No schedules available.") : (puts "Found destination")

    enter_depart_date
    enter_return_date
    submit_page1 == "Error" ? (puts "Error - Couldnt submit form"; @browser.close; return "No greyhound bus schedules available.") : (puts "Form submitted successfully")

    get_depart_data
  end
end
