require "json"
require "open-uri"
require 'soda'
require 'rest_client'
require 'proj4'
require 'date'



client = SODA::Client.new({:domain => "XXXX", :username => "XXXX", :password => "XXXX", :app_token => "XXXX"})



@rows =[]


  x = open("http://maps.bristol.gov.uk/arcgis/rest/services/ext/moving_home/FeatureServer/59/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&gdbVersion=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&f=pjson","Content-Type" => "text/json")


sites=JSON.parse( x.read)

sites["features"].each do |l|

  easting = l["geometry"]["points"][0][0]
  northing = l["geometry"]["points"][0][1]
  srcPoint = Proj4::Point.new(easting, northing)
  srcProj = Proj4::Projection.new('+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs')
  dstProj = Proj4::Projection.new('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')


  dstPoint = srcProj.transform(dstProj, srcPoint)

  lat=(dstPoint.lat * (180 / Math::PI)).round(4)
  lon=(dstPoint.lon * (180 / Math::PI)).round(4)
  st_date = (Time.at(l["attributes"]["START_DATE"]/1000).to_datetime).to_s[0..9]
  en_date = (Time.at(l["attributes"]["END_DATE"]/1000).to_datetime).to_s[0..9]

@rows << [l["geometry"]["points"][0][0],
    l["geometry"]["points"][0][1],
    lat,
    lon,
    l["attributes"]["OBJECTID"],
    l["attributes"]["ROAD"],
    l["attributes"]["NATURE_OF_WORKS"],
    l["attributes"]["DESCRIPTION"],
    st_date,
    en_date,
    l["attributes"]["WEATHER_DEPENDENT"],
    l["attributes"]["SEVERITY"],
    l["attributes"]["STATUS"],
    l["attributes"]["INFO_TODAY"]]

end

@update = []

@rows.each do |x|

     @update << {
      "gb_gr_x" => x[0], 
      "gb_gr_y" => x[1],
      "lat" => x[2],
      "lon" => x[3],
      "OBJECTID" => x[4],
      "ROAD"  => x[5],
      "NATURE_OF_WORKS" => x[6],
      "DESCRIPTION" => x[7],
      "START_DATE" => x[8],
      "END_DATE" => x[9],
      "WEATHER_DEPENDENT" => x[10],
      "SEVERITY" => x[11],
      "STATUS" => x[12],
      "INFO_TODAY" => x[11],
      "location" => {
    "longitude" => x[3],
    "latitude" => x[2]
   }

    }
end

puts @update

@response = client.put("XXXX-XXXX", @update)

#USE WITH EXTREME CARE THIS CLEARS DATASET
#@response = client.put("ak9k-3z8a",{})
