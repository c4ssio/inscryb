module HttpGmaps

require 'net/https'


# Create a simple method to obtain a feed
def self.get_feed
http = Net::HTTP.new('www.google.com', 443)

http.use_ssl = true

path = '/accounts/ClientLogin'

# Now we are passing in our actual authentication data. 
# Please visit this link for more information 
# about the accountType parameter
data = \
'accountType=HOSTED_OR_GOOGLE&Email=cassio.paesleme@gmail.com' \
'&Passwd=fernando' \
'&service=local'

# Set up a hash for the headers
headers = \
{ 'Content-Type' => 'application/x-www-form-urlencoded'}

# Post the request and print out the response to retrieve our authentication token
resp, data = http.post(path, data, headers)

# Strip out our actual token (Auth) and store it
cl_string = data[/Auth=(.*)/, 1]

# Build our headers hash and add the authorization token
headers["Authorization"] = "GoogleLogin auth=#{cl_string}"

# Store the URI to the feed since we may want to use it again
local_uri = \
'http://maps.google.com/maps/feeds/maps/default/full'
  
  uri = URI.parse(local_uri)
  Net::HTTP.start(uri.host, uri.port) do |http|
    return http.get(uri.path, headers)
  end
end


end