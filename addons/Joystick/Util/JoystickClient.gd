# Node description
## A Node that allows easly connect to Joystick service. [br]
## See more about in: [i]https://www.getjoystick.com[/i]
@icon("../Icons/JoystickClientNode.png")
extends Node
class_name JoystickClient

@export var _apiKey : String = "" # Here are stored the key of the API
var _http = HTTPRequest.new() # Here are stored a intance og HTTPRequest

func _init( apiKey : String = "" ):
	if apiKey != "":
		_apiKey = apiKey
	else:
		if _apiKey == "":
			assert(false, "Parmeter \"Api Key\" need to be a valid key!")
		
	# Add the http node to the tree
	add_child(_http)

# Result of the async methods
## Emmited when the requests as completed. [br]
## Returns [param data] as the data requested. [br]
## This can be used to make async requests. Example:
## [codeblock]
## # GDscript ref #
##
## func _placehoder():
##     # First of all, connect the signal in a method
##     JoystickClient.request_completed.connect(self._request_completed)
##
##     JoystickClient.get_content("content-id1")
##     # /\ Just call the function, don't put the result in
##     # any variable nor call it with "wait"
##
##func _request_completed(data):
##    print(data) # Will print the requested data when it was recived
## [/codeblock]
signal request_completed (data : Dictionary)

# Basic configs of the httpRequest
func _config_HTTPRequest( contentId : String ):
	# Configure URL
	var url = "https://api.getjoystick.com/api/v1/config/" + contentId + "/dynamic"
	# Configure Headers
	var headers = ['X-Api-Key: ' + _apiKey, 'Content-Type: application/json']
	# Configure Method
	var method = HTTPClient.METHOD_POST
	# Configure Body
	var body = {"u": "", "p": {}}
	
	return [ url, headers, method, JSON.stringify(body) ]


## Request a single configuration. [br]
## Can be used in sync or async method. [br]
## [param contentId] is your config name/ID.
## See the example of how to use it:
## [codeblock]
## # GDscript ref #
##
## var result = await JoystickClient.get_content("content-id1")
## print(result) #Will print a Dictionary the data present in "content-id1" config
## [/codeblock]
func get_content( contentId : String ) -> Dictionary:
	# Get url (0), headers (1), method (2) and body (3)
	var config = _config_HTTPRequest( contentId )
	# Connect the request_completed signal
	_http.request_completed.connect(self._single_request_completed)
	# Make the request and wait
	_http.request( config[0],  config[1],  config[2],  config[3])
	var res = await _http.request_completed
	# Filtrate the info and return
	var json = JSON.new()
	json.parse(res[3].get_string_from_utf8())
	return(json.get_data().data)

## Request multiple configurations at the same request. [br]
## Can be used in sync or async method. [br]
## [param contentsId] is a array of strings with the configs name/ID, one per array item.
## See the example of how to use it:
## [codeblock]
## # GDscript ref #
##
## var result = await JoystickClient.get_contents(["content-id1", "content-id2"])
## print(result) #Will print a Dictionary with the data present in "content-id1" & "content-id2"
## [/codeblock]
func get_contents( contentsId : Array[String] ) -> Dictionary:
	# Get headers (1), method (2) and body (3)
	var config = _config_HTTPRequest("null") # the that this returns dont is used here
	
	#Get the correct Url for multiple configs
	var url = "https://api.getjoystick.com/api/v1/combine/?c=" + \
	JSON.stringify(contentsId) + "&dynamic=true"
	
	# Connect the request_completed signal
	_http.request_completed.connect(self._multiple_request_completed)
	
	# Make the request and wait
	_http.request( url,  config[1],  config[2],  config[3])
	var res = await _http.request_completed
	# Filtrate the data
	var json = JSON.new()
	json.parse(res[3].get_string_from_utf8())
	var data = json.get_data()
	# Apeend the results in results dict and return
	var result = {}
	for i in data:
		result[i] = data[i].data
	return result


# This methods filtrate the async responses before send back
func _single_request_completed(_res, _response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data().data
	request_completed.emit(data)
	# Disconnect the request_completed to sync functions don't call
	# this signals intentionaly
	_http.request_completed.disconnect(self._single_request_completed)
func _multiple_request_completed(_res, _response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()
	
	# Apeend the results in results dict
	var result = {}
	for i in data:
		result[i] = data[i].data
	
	request_completed.emit(result)
	
	# Disconnect the request_completed to sync functions don't call
	# this signals intentionaly
	_http.request_completed.disconnect(self._multiple_request_completed)
