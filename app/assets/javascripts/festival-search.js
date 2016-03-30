$(function() {
  // DATE PICKER
  // set max date to account for greyhound search limit
  function maxDay() {
    var d = new Date();
    d.setDate(d.getDate() + 320);
    return d;
  }

  $('#date-picker').datepicker({
    minDate: new Date(),
    maxDate: maxDay(), 
    dateFormat: 'yy-mm-dd'
  });

  // SET USER LOCATION
  var locationInput = $('#get_location');
  var usrLocation = $('#usr_location');
  locationInput.hide();

  $('#edit_location').on('click', function() {
    var inputBtn = $(this);
    inputBtn.hide();
    usrLocation.hide();
    locationInput.show();    

    locationInput.on('blur paste', function() {
      usrLocation.text( locationInput.val() );
      usrLocation.show();
      $(this).hide();
      inputBtn.show();
      $.ajax('/usr-info',
        { dataType: 'json',
          type: 'POST',
          data: {usr_location: usrLocation.text()},
          success: function() { console.log('user location set'); },
          error: function(xhr) { console.log(xhr.statusText); }
        });
    });
  });
  
  // SOULMATE AUTO-COMPLETE
  var render, select;
  render = function(term, data, type) {
    return term;
  };
  select = function(term, data, type) {
    $('#search-artist').val(term);
    $('ul#soulmate').hide();
  };

  $('#search-artist').soulmate({
    url: '/soulmate/search',
    types: ['artists'],
    renderCallback: render,
    selectCallback: select,
    minQueryLength: 2,
    maxResults: 5
  });

  // DISPLAY WHILE WAIT FOR RESULTS TO LOAD
  $('#submit-search').on('click', function(event, data) {
    $('#search-results').empty();
    $('#search-results').html('<p>Loading...</p>');
  });

  // POPULATE SEARCH RESULTS
  function formatResults(label,ele, div) {
    if (ele === null || ele === 0) {
      $('<div>').text(label + ': n/a').appendTo(div);
    }
    else {
      $('<div>').text(label + ': ' + ele).appendTo(div);
    }
  }

  $('#festival-search').on('ajax:success', function(event, data) {
    var results = $('#search-results');
    results.empty();

    if (data.length === 0) { results.text('No results found'); }

    data.forEach(function(festival) {
      var festivalDiv = $('<div>').appendTo(results);

      $('<a>').attr('href', '/festivals/' + festival.id)
        .text(festival.name)
        .appendTo(festivalDiv);

      var festivalDetails = $('<div>').addClass('festival-result')
                              .attr('data-id', festival.id)
                              .appendTo(festivalDiv);
                              
      $('<div>').text('Location: ' + festival.location).appendTo(festivalDetails );
      $('<div>').text('Date: ' + festival.date).appendTo(festivalDetails);

      formatResults('Price', festival.price, festivalDetails);
      formatResults('Camping', festival.camping, festivalDetails);
      formatResults('Description', festival.description, festivalDetails);
    });
  });

});
