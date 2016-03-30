$(function() {

  // ADD OR REMOVE FESTIVALS FROM FAVORITES ON FESTIVAL SHOW PAGE
  $('.cache-btns').on('click', '.fave-btn',function() {
    var driving = $('.driving-cost');
    var tripCost = {
      festivalId: $('.music-festival').attr('data-id'),
      drivingPrice: driving.attr('data-car-price'),
      drivingTime: driving.attr('data-car-time')
    };
    $.ajax('/festival-select',
      { dataType: 'json',
        type: 'POST',
        data: tripCost
      });
    $(this).replaceWith('<button class="remove-btn">Remove from Favourites</button>');
  });

  $('.cache-btns').on('click', '.remove-btn', function() {
    $(this).replaceWith('<button class="fave-btn">Add to Favourites</button>');
    $.ajax('/festival-unselect',
      { dataType: 'json',
        type: 'POST', 
        data: { festivalId: $('.music-festival').attr('data-id') }
      });
  });
  // REMOVE FESTIVALS FROM FESTIVAL FAVOURITES PAGE
  $('.remove-fave').on('click', function() {
    var festivalDiv = $(this).closest('.fave-festival');
    var data = { festivalId: festivalDiv.attr('data-id') };
    $.ajax('/festival-unselect', 
      { dataType: 'json',
        type: 'POST',
        data: data,
        complete: function() { festivalDiv.remove(); }
      });
  });

  // debugger;

  var carPrice = $('.driving-cost')[0].dataset.carPrice;

  //Load Driving Directions on Festival Details page

    var drivingMapDiv = $('#travel-tabs').find('#driving-map');
    var destinationCoords = {
      lat: drivingMapDiv[0].dataset.latitude,
      long: drivingMapDiv[0].dataset.longitude
    };

    var departure = new google.maps.LatLng(49.246, -123.116);

    var destination = new google.maps.LatLng(destinationCoords.lat, destinationCoords.long);
    var map;
    var map2;
    var festivalMarker;

    var festivalMaps = {

    loadDrivingMap: function() {

      map = new google.maps.Map(document.getElementById('driving-map'), {
        center: departure,
        scrollwheel: false,
        zoom: 8
      });

      var directionsDisplay = new google.maps.DirectionsRenderer({
        map: map
      });

      // Set destination, origin and travel mode.
      var request = {
        destination: destination,
        origin: departure,
        travelMode: google.maps.TravelMode.DRIVING
      };

      // Pass the directions request to the directions service.
      var directionsService = new google.maps.DirectionsService();
      directionsService.route(request, function(response, status) {
        if (status == google.maps.DirectionsStatus.OK) {
          // Display the route on the map.
          directionsDisplay.setDirections(response);
          }
       });
     },
    loadFestivalMap: function() {

      map2 = new google.maps.Map(document.getElementById('festival-map'), {
        center: destination,
        scrollwheel: false,
        zoom: 8
      });

      // debugger;
      festivalMarker = new google.maps.Marker({
        position: destination,
        map: map2
     });

  },

  resetDrivingMap: function() {
    google.maps.event.trigger(map, "resize");
    map.setCenter(departure);
    map.setZoom(4);
    },
  };

  festivalMaps.loadFestivalMap();

  if ($('#festival-show').length > 0 && carPrice > 0) {
    festivalMaps.loadDrivingMap();

  }
  
  // show first content by default
  $('#tabs-nav li:first-child').addClass('active');

  // click function
  $('#festival-show').on('click', '#tabs-nav li', function(event){

    event.preventDefault();

    $('#tabs-nav li').removeClass('active');
    $(this).addClass('active');
    $('.content:not(".hidden")').removeClass('active').addClass('hidden');

    var activeTab = $(this).find('a').attr('href');
    $(activeTab).removeClass('hidden').addClass('active');
    $(activeTab).fadeIn();

    if (carPrice > 0) {
      festivalMaps.resetDrivingMap();
    }

  });


  //Travel tabs
  $('#festival-show').on('click', '#travel-tabs li', function(event){

    event.preventDefault();

    $('.route-details:not(".hidden")').removeClass('active').addClass('hidden');

    var activeTravelTab = $(this).find('a')[0].dataset.div;

    $(activeTravelTab).addClass("active").removeClass("hidden");
    $(activeTravelTab).fadeIn();

    if (carPrice > 0) {

      festivalMaps.resetDrivingMap();
    }

  });

  $('#festival-show').on('click', '#flight-search-btn', function() {
    $('#flight-search-form').slideToggle(200);
  });


  // FLICKR
  if ($('#festival-show').length > 0) {

    var festival = $('.flickr-imgs').data('name');
    $.ajax('/flickr_images/' + festival, { dataType: 'json' }).done(function(data) { 
      if (data.stat != 'ok') { return console.log('error'); }
   
      var imgs = data.photos.photo;
      imgs.forEach(function(img) { 
        var imgSrc = 'https://farm'+img.farm+'.staticflickr.com/'+img.server+'/'+img.id+'_'+img.secret+'.jpg';
        $('<img>').attr('src', imgSrc).appendTo('.flickr-imgs');
      });
    });
  }

  
  var target = $('#wel');
  var targetHeight = target.outerHeight();

  $(window).scroll(function(){
    var scrollPercent = (targetHeight - window.scrollY) / targetHeight;
    if(scrollPercent >= 0){
      target.css('opacity', scrollPercent);
    }
  }); 

 // var map;
 //      function initMap() {
 //        map = new google.maps.Map(document.getElementById('map'), {
 //          center: {lat: -34.397, lng: 150.644},
 //          zoom: 8
 //        });
 //      }
 // }
});

function initMap() {
  var myLatLng = {lat: 49.2827, lng: -123.1207};
  var map;

  map = new google.maps.Map(document.getElementById('map'), {
    center: myLatLng,
    zoom: 7
  });

  var marker = new google.maps.Marker({
    map: map,
    position: myLatLng,
    title: 'Hello World'
  });

  $.getJSON("/festivals", function(data) {
    $.each(data, function(index, festival) {
      var marker = new google.maps.Marker({
        map: map, 
        position: {lat:festival.latitude, lng:festival.longitude}, 
        name: name
      });
      // var contentString = "This is a string";
      var infowindow = new google.maps.InfoWindow({
        content: (festival.name + ',' + ' ' + festival.date)
      });
      marker.addListener('click', function() {
        console.log("listener");
        infowindow.open(map, marker);
        infowindow.addListener('closeclick', function() {
          infowindow.close();
        });
      // setTimeout(function(){
      //   infowindow.close();
      // },3000)
      });
    });
  });

  $(".map_button").click(function(){
    $("#map").toggle(300);
  });

  $('.pan_button').on('click', function(){
    var latLng = new google.maps.LatLng(49.8994, -97.1392); //should pan to specified location (based on card/div?)
    map.panTo(latLng);
  });
} 
