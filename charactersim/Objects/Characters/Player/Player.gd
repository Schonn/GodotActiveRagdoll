extends Spatial

var movingDirections = null
var viewPanning = null
var objectGrabbing = null
var hasGrabbedObject = null
var previousMousePosition = null

func _ready():
	self.movingDirections = [0,0,0,0]
	self.viewPanning = false
	self.previousMousePosition = Vector3(0,0,0)
	self.objectGrabbing = false
	self.hasGrabbedObject = false
	self.set_process_input(true)
	pass
	
func _process(delta):
	var frontMoveAmount = 0
	var sideMoveAmount = 0
	if(movingDirections[0] != 0):
		frontMoveAmount = movingDirections[0]
	elif(movingDirections[1] != 0):
		frontMoveAmount = movingDirections[1]
	if(movingDirections[2] != 0):
		sideMoveAmount = movingDirections[2]
	elif(movingDirections[3] != 0):
		sideMoveAmount = movingDirections[3]
	if(frontMoveAmount != 0 or sideMoveAmount != 0):
		self.get_node("Camera").translate_object_local(Vector3(sideMoveAmount*0.5,0,frontMoveAmount*0.5))
	if(viewPanning == true):
		var screenCenter = Vector2(get_viewport().get_visible_rect().size.x/2,get_viewport().get_visible_rect().size.y/2)
		if(get_viewport().get_mouse_position() != screenCenter):
			self.get_node("Camera").rotation_degrees = Vector3(self.get_node("Camera").rotation_degrees.x - (get_viewport().get_mouse_position().y-previousMousePosition.y)/2,self.get_node("Camera").rotation_degrees.y - (get_viewport().get_mouse_position().x-previousMousePosition.x)/2,0)
			previousMousePosition = get_viewport().get_mouse_position()
			#get_viewport().warp_mouse(screenCenter)
	var newMouseRayLocation = (self.get_node("Camera").to_local(self.get_node("Camera").project_position(get_viewport().get_mouse_position())))
	newMouseRayLocation[0] *= 1000
	newMouseRayLocation[1] *= 1000
	self.get_node("Camera/mouseLocationHelper").set("translation",newMouseRayLocation)
	var objectMovingDetectionRay = self.get_node("Camera/grabRay")
	objectMovingDetectionRay.look_at(self.get_node("Camera/mouseLocationHelper/mouseHelperEnd").get_global_transform().origin,Vector3(0,1,0))
	var movementAxes = ["x","y","z"] #axes for enabling and disabling joints
	var grabJoint = self.get_node("Camera/grabRay/physicsConnector/playerDragJoint")
	if(objectMovingDetectionRay.is_colliding() and self.objectGrabbing == true and self.hasGrabbedObject == false):
		var grabObject = objectMovingDetectionRay.get_collider()
		grabJoint.set("nodes/node_b",grabObject.get_path())
		grabObject.apply_central_impulse(Vector3(0.1,0.1,0.1))
		self.hasGrabbedObject = true
		for movementAxis in range(0,len(movementAxes)):
			grabJoint.set("linear_limit_" + movementAxes[movementAxis] + "/enabled",true) #make sure that the phys joint is back on
			grabJoint.set("angular_limit_" + movementAxes[movementAxis] + "/enabled",true)
	elif(grabJoint.get("nodes/node_b") != "noGrabObject" and self.objectGrabbing == false):
		grabJoint.set("nodes/node_b","noGrabObject")
		self.hasGrabbedObject = false
		for movementAxis in range(0,len(movementAxes)):
			grabJoint.set("linear_limit_" + movementAxes[movementAxis] + "/enabled",false) #make sure that the phys joint is back on
			grabJoint.set("angular_limit_" + movementAxes[movementAxis] + "/enabled",false)
	

	
	
func _input(event):
	if(event.is_action_pressed("gred_viewmove")):
		self.previousMousePosition = get_viewport().get_mouse_position()
		self.viewPanning = true
	if(event.is_action_pressed("gred_playerpickup")):
		self.objectGrabbing = true
	if(event.is_action_pressed("gred_forwards")):
		self.movingDirections[0] = -1
	if(event.is_action_pressed("gred_backwards")):
		self.movingDirections[1] = 1
	if(event.is_action_pressed("gred_strafeleft")):
		self.movingDirections[2] = -1
	if(event.is_action_pressed("gred_straferight")):
		self.movingDirections[3] = 1
	if(event.is_action_released("gred_viewmove")):
		self.viewPanning = false
	if(event.is_action_released("gred_playerpickup")):
		self.objectGrabbing = false
	if(event.is_action_released("gred_forwards")):
		self.movingDirections[0] = 0
	if(event.is_action_released("gred_backwards")):
		self.movingDirections[1] = 0
	if(event.is_action_released("gred_strafeleft")):
		self.movingDirections[2] = 0
	if(event.is_action_released("gred_straferight")):
		self.movingDirections[3] = 0
	
