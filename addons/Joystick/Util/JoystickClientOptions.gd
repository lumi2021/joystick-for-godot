##Head more about in Joystick Docs [br]
##[i]https://docs.getjoystick.com[/i]
@icon("../Icons/JoystickClientOptionsRes.png")
extends Resource
class_name JoysticClientOptions

##The unique identifier for a particular user. [br]
##Joystick use this identifier to split users into sticky AB Test groups.
var uniqueUserId : String = ""
##This is the semantic version of your app that is making the request.
##Joystick highly recommend sending this as we are able to deliver backward compatible revisions of configuration based on semantic versioning.
var version : String = "1.0.0"

##This is a dictionary of key:value attributes that can be used by Joystick for segmentation.
var parameters : Dictionary = {}
