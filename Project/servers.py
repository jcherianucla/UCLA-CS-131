import conf, sys, json, datetime
from twisted.internet.protocol import Protocol, ServerFactory, ClientFactory
from twisted.python import log
from twisted.web.client import getPage
from twisted.internet import reactor

# Server Protocol implementation
class ProxyHerdProtocol(Protocol):

	# Parse the data and respond based on the given data
	def dataReceived(self, data):
		split_data = data.split()
		# Invalid number of args
		if len(split_data) < 2:
			print("? {0}".format(data))
			return

		error_flag = False

		if split_data[0] == "IAMAT":
			if self.checkIAMATInput(split_data[1:]): self.IAMAT(split_data[1:])
			else: error_flag = True
		elif split_data[0] == "WHATSAT":
			if self.checkWHATSATInput(split_data[1:]): self.WHATSAT(split_data[1:])
			else: error_flag = True
		elif split_data[0] == "AT":
			if self.checkATInput(split_data): self.AT(data)
			else: error_flag = True
		else:
			error_flag = True
		# Handle errors
		if error_flag:
			print("? {0}".format(data))
	
	# Update the cache only if necessary
	def updateCache(self, client, msg):
		# If this client didn't exist before, store it now
		if not self.factory.cache.get(client, 0):
			self.factory.cache[client] = msg
			log.msg("NEW_MSG: Adding message {0} to cache field {1}".format(msg, client))
		else:
			stored_time = float(self.factory.cache[client].split()[-2])
			current_time = float(msg.split()[-2])
			# Update the cache only if the client IAMAT time is later than
			# previously stored
			if stored_time < current_time:
				self.factory.cache[client] = msg
				log.msg("UPDATE_MSG: Updating message {0} to cache field {1}".format(msg, client))
			else:
				log.msg("NOOP_MSG: Stored timestamp for cache field {0} is smaller".format(client))

	# If the propagated message is the same as what's in the cache
	# Then we are in a cycle and can stop the propagation
	def endPropagation(self, client, msg):
		stored_server_time = float(self.factory.cache[client].split()[-1])
		passed_server_time = float(msg.split()[-1])
		return True if stored_time == current_time else False
	
	# Validate GPS position and set it
	def validateGPS(self, combined):
		lat, lng, i = [], [], 1
		for val in combined[i:]:
			if val in ['-', '+']: break
			i += 1
		lat, lng = combined[:i], combined[i:]
		try:
			temp_lat, temp_lng = float(lat), float(lng)
			if temp_lat > 90 or temp_lat < -90: return False
			if temp_lng > 180 or temp_lng < -180: return False
			self.factory.lat, self.factory.lng = temp_lat, temp_lng
			return True
		except ValueError:
			log.err("IAMAT_GPS: {0} and {1} not valid coordinates as per ISO 6709".format(lat, lng))
			return False

	# Pre-condition: givenTime is a float
	# Returns a string reporting the time difference from client send to server receive
	def getTimeDiff(self, givenTime):
		diff = datetime.datetime.utcnow() - datetime.datetime.fromtimestamp(givenTime)
		return '+' + str(diff.total_seconds()) if diff.total_seconds() >= 0 else str(diff.total_seconds())

	# Validate input for IAMAT
	def checkIAMATInput(self, data):
		if len(data) != 3:
			log.err("IAMAT_LENGTH: {0} does not have 3 fields".format(data))
			return False
		if not self.validateGPS(data[1]):
			return False
		# Make sure the time is valid as a float
		try:
			self.factory.client_time = float(data[-1])
			return True
		except ValueError:
			log.err("IAMAT_TIME: {0} is not in valid format".format(data[-1]))
			return False
	
	# Validate input for WHATSAT
	def checkWHATSATInput(self, data):
		if len(data) != 3:
			log.err("WHATSAT_LENGTH: {0} does not have 3 fields".format(data))
			return False
		if int(data[1]) > 50:
			log.err("WHATSAT_RADIUS: {0} not in valid range".format(data[1]))
			return False
		if int(data[-1]) > 20:
			log.err("WHATSAT_LIMIT: {0} not in valid range".format(data[-1]))
			return False
		return True
	
	# Validate input for AT
	def checkATInput(self, data):
		if len(data) != 7:
			log.err("AT_LENGTH: {0} does not have 7 fields".format(data))
			return False
		try:
			time_diff = float(data[2])
			server_time = float(data[-1])
		except ValueError:
			log.err("TIME_ERROR: Timing values in {0} is/are not valid".format(data))
			return False
		return self.checkIAMATInput(data[3:-1])

	# Run the IAMAT command
	def IAMAT(self, data):
		# Create the response string
		iamat_msg = "AT {0} {1} {2}\n".format(self.factory.server_name, self.getTimeDiff(self.factory.client_time), ' '.join(data))
		log.msg("IAMAT: Sending {0} to client".format(iamat_msg)) 
		# Send the data to the client
		self.transport.write(iamat_msg)
		# Save the current timestamp and store in cache for unique identification
		curr_time = (datetime.datetime.utcnow() - datetime.datetime(1970,1,1)).total_seconds()
		save_msg = iamat_msg + str(float(curr_time))
		# Save the client information in server cache
		self.updateCache(data[0], save_msg)
		# Make neighbors aware of change
		self.propagate(self.factory.cache[data[0]])

	# Create the endpoint to get information from
	def generateEndPoint(self, data):
		key = "key=" + conf.API_KEY
		location = "location=" + str(self.factory.lat) + "," + str(self.factory.lng)
		radius = "radius=" + str(int(data[1])*1000)
		params = location + "&" + radius + "&" + key
		endpoint = conf.API_ENDPOINT + params
		return endpoint

	# Send the data through to neighbors
	def propagate(self, msg):
		# Get the servers neighbors
		neighbors = conf.NEIGHBORS[self.factory.server_name]
		# Send the message to the neighbors
		for neigh in neighbors:
			log.msg("CONNECT_TCP: Connecting to {0} to propagate {1}".format(neigh, msg))
			reactor.connectTCP('localhost', conf.PORT_NUM[neigh], ProxyClientFactory(msg))
	
	# Run the WHATSAT command
	def WHATSAT(self, data):
		endpoint = self.generateEndPoint(data)
		log.msg("GET: Grabbing Google Nearby information from {0}".format(endpoint))
		google_response = getPage(endpoint)
		google_response.addCallback(self.processResponse, data[0], data[-1])
		google_response.addErrback(self.processError)

	# Get the JSON data from Google Places and create the final message
	# with the cached client message
	def processResponse(self, resp, client, limit):
		data = json.loads(resp)
		result = data["results"]
		result = result[:int(limit)]
		data["results"] = result
		stored_msg = self.factory.cache[client]
		# Ignore the last field, since that's for propagation identificaiton to prevent cycles
		whatsatmsg = " ".join(stored_msg.split()[:-1])
		final_msg = "{0}{1}\n\n".format(whatsatmsg, json.dumps(data, indent=4))
		log.msg("WHATSAT: Message transported is {0}".format(final_msg))
		self.transport.write(final_msg)
	
	def processError(self, error):
		log.err("CALLBACK_ERROR")
	
	# Make sure all servers in the herd are up to date with the AT location
	# End the propagation if we come back in a cycle
	def AT(self, data):
		split_data = data.split()
		client = split_data[3]
		self.updateCache(client, data)
		if self.endPropagation(client, split_data):
			log.msg("END_PROPAGATION: Stored and current timestamps for cache field {0} are the same".format(client))
			return
		else:
			prop_data = self.factory.cache[client]
			log.msg("PROPAGATE: Propagate {0} forward to neighbors for cache field {1}".format(prop_data, client))
			self.propagate(prop_data)
		
# Server Factory implementation
class ProxyHerdFactory(ServerFactory):

	# Tell base class what protocol to build
	protocol = ProxyHerdProtocol

	# Set up the factory and logging
	def __init__(self, server_name):
		self.server_name = server_name
		self.lat, self.lng = None, None
		self.client_time = None
		self.cache = {}
		file_name = server_name + str(datetime.datetime.now()) + ".log"
		log.startLogging(open(file_name, 'w'))

	# Begin the server
	def startFactory(self):
		log.msg("Starting server")
	
	# Stop the server
	def stopFactory(self):
		log.msg("Stopping server")

# Client Protocol Implementation
class ProxyClientProtocol(Protocol):

	# Once the connection is made through TCP, write the data
	# and then close the connection
	def connectionMade(self):
		self.transport.write(self.factory.data)
		self.transport.loseConnection()

# Client Factory implementation
class ProxyClientFactory(ClientFactory):

	# Tell base class what protocol to build
	protocol = ProxyClientProtocol

	# Just set the data for all protocols to reference
	def __init__(self, data):
		self.data = data

def main():
	# Ensure correct number of args
	if(len(sys.argv) != 2):
		print("Usage: [Server Name]")
		exit(1)

	portno = 0
	servername = sys.argv[1]
	# Get the port number from conf if valid
	if not conf.PORT_NUM.get(servername, 0):
		print("Invalid Server Name. Please use Alford, Ball, Hamilton, Holiday or Welsh as server names.")
		exit(1)
	else:
		portno = conf.PORT_NUM[servername]

	# Test the server name to port allocation - uncomment to see what server is being setup
        #print("SERVER: {0} - PORTNUM: {1}".format(servername, str(portno)))

	# Build the factory to server the protocol
	factory = ProxyHerdFactory(servername)
	reactor.listenTCP(portno,factory)
	reactor.run()

if __name__ == "__main__": main()
