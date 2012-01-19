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

clubLocations = [];
clubsByLocation = {};

function placeClub(club) {
  if(!clubsByLocation[club.location]) {
    clubsByLocation[club.location] = [];
    clubLocations.push(club.location);
  }
  clubsByLocation[club.location].push(club);
}

function drawMapMarkers(fit) {
  var mapbounds = new google.maps.LatLngBounds();
  for(var i=0; i<clubLocations.length; i++) {
    var location = clubLocations[i];
    var clubs = clubsByLocation[location];
    var pin = new google.maps.LatLng(clubs[0].lat, clubs[0].lng);
    var names = [];
    var infos = [];
    for(var j=0; j<clubs.length; j++) {
      names.push(clubs[j].name);
      infos.push('<p><strong><a href="' + clubs[j].url + '">' + clubs[j].name + '</a></strong><br/>' + clubs[j].schedule + '</p>');
    }
    buildMarker(pin, names.join(', '), '<p>' + location + '</p>' + infos.join(''));
    mapbounds.extend(pin);
  };
  if(fit) map.fitBounds(mapbounds);
}

function buildMarker(pin, title, content) {
  var marker = new google.maps.Marker({
    position: pin,
    map: map,
    title: title
  });
  google.maps.event.addListener(marker, 'click', function() {
    infowin.close()
    infowin.setContent(content);
    infowin.open(map, marker);
  });
}
