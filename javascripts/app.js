function mapInit(lat, lng, zoom) {
  var loc = new google.maps.LatLng(lat, lng);
  var myOptions = {
    center: loc,
    zoom: zoom,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  window.map = new google.maps.Map(document.getElementById("map_canvas"),
    myOptions);
  window.infowin = new google.maps.InfoWindow();
}

function placeClub(club) {
  var loc = new google.maps.LatLng(club.lat, club.lng);
  var marker = new google.maps.Marker({
    position: loc,
    map: window.map,
    title: club.name
  });
  google.maps.event.addListener(marker, 'click', function() {
    infowin.close()
    infowin.setContent('<p><strong><a href="' + club.url + '">' + club.name + '</a></strong></p</p><p>' + club.location + '</p><p>' + club.schedule + '</p>');
    infowin.open(window.map, marker);
  });
}
