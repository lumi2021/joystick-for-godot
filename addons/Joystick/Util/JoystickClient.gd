# Node description
## A Node that allows easly connect to Joystick service. [br]
## See more about in: [i]https://www.getjoystick.com[/i]
@icon("../Icons/JoystickClientNode.png")
extends Node
class_name JoystickClient

@export var _apiKey : String = "" # Here are stored the key of the API
@export var _options : JoysticClientOptions = null

var _requestBody : Dictionary :
	get:
		var rawBody = {"u": "", "p": {}}
		if _options == null: return rawBody
		
		rawBody["u"] = _options.uniqueUserId
		rawBody["v"] = _options.version
		rawBody["p"] = _options.parameters
		
		return {}

##The type of the response. [br]
##read the joystick docs for more info.
enum {
	response_type_default,
	response_type_dynamic,
	response_type_serialised
}
##This enumerator is used only inside the class, ignore that!
enum _REQUEST_TYPE {single_config, multi_config, catalog}

var _http = HTTPRequest.new() # Here are stored a intance of HTTPRequest

func _init( apiKey : String = "", options : JoysticClientOptions = null):
	#Verify Api Key
	if apiKey != "":
		_apiKey = apiKey.strip_edges()
	else:
		if _apiKey.strip_edges() == "":
			assert(false, "Parmeter \"Api Key\" need to be a valid key!")
	
	_options = options
	
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
func _config_HTTPRequest(
	contentId,
	mode : _REQUEST_TYPE,
	responseType : int
):
	# Configure URL
	var url = "https://api.getjoystick.com/api/v1/"
	
	if mode == _REQUEST_TYPE.single_config:
		url += "config/" + contentId
		if responseType != response_type_default:
			url += "/dynamic" + \
			("?responseType=serialized" if responseType == response_type_serialised \
			else "")
		
	elif mode == _REQUEST_TYPE.multi_config:
		url += "combine/?c=" + JSON.stringify(contentId)
		if responseType != response_type_default:
			url += "&dynamic=true" + \
			("&responseType=serialized" if responseType == response_type_serialised \
			else "")
	
	# Configure Headers
	var headers = ['X-Api-Key: ' + _apiKey, 'Content-Type: application/json']
	# Configure Method
	var method = HTTPClient.METHOD_POST
	# Configure Body
	var body = _requestBody
	
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
func get_content(
	contentId : String,
	response_type : int = response_type_default
) -> Dictionary:
	
	# Get url (0), headers (1), method (2) and body (3)
	var config = _config_HTTPRequest(
		contentId,
		_REQUEST_TYPE.single_config,
		response_type
	)
	
	# Connect the request_completed signal
	_http.request_completed.connect(self._request_completed)
	# Make the request and wait
	_http.request( config[0],  config[1],  config[2],  config[3])
	var res = await _http.request_completed
	# Filtrate the info and return
	var json = JSON.new()
	json.parse(res[3].get_string_from_utf8())
	return(json.get_data())

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
func get_contents(
	contentsId : Array[String],
	response_type : int = response_type_default
) -> Dictionary:
	
	# Get url (0), headers (1), method (2) and body (3)
	var config = _config_HTTPRequest(
		contentsId,
		_REQUEST_TYPE.multi_config,
		response_type
	)
	
	# Connect the request_completed signal
	_http.request_completed.connect(self._request_completed)
	
	# Make the request and wait
	_http.request(config[0],  config[1],  config[2],  config[3])
	var res = await _http.request_completed
	# Filtrate the data
	var json = JSON.new()
	json.parse(res[3].get_string_from_utf8())
	var data = json.get_data()
	_check_for_response_errors(data)
	return data

## Request information about all the configurations in the api key enviropment. [br]
## Can be used in sync or async method. [br]
## See the example of how to use it:
## [codeblock]
## # GDscript ref #
##
## var result = await JoystickClient.get_catalog()
## print(result) #Will print a Dictionary with the information about each one configuration
## [/codeblock]
func get_catalog() -> Dictionary:
	# Connect the request_completed signal
	_http.request_completed.connect(self._request_completed)
	
	var url = "https://api.getjoystick.com/api/v1/env/catalog"
	var headers = ['X-Api-Key: ' + _apiKey, 'Content-Type: application/json']
	
	# Make the request and wait
	_http.request(url, headers, HTTPClient.METHOD_GET, "")
	var res = await _http.request_completed
	
	# Filtrate the data
	var json = JSON.new()
	json.parse(res[3].get_string_from_utf8())
	var data = json.get_data()
	_check_for_response_errors(data)
	return data

# This method filtrate the async responses before send back
func _request_completed(_res, _response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()
	_check_for_response_errors(data)
	request_completed.emit(data)
	# Disconnect the request_completed to sync functions don't call
	# this signals intentionaly
	_http.request_completed.disconnect(self._request_completed)

func _check_for_response_errors(res):
	if typeof(res) == 27:
		if res.has("message") and \
		typeof(res.message) == 4:
			assert(false, "API returned: " + res.message)
		
		elif res.has("Message"):
			assert(false, "API returned: " + res.Message)
