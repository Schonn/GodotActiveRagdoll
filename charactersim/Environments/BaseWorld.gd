extends Spatial

#iterator for stepping through the scene and creating links between objects
var sceneScanIterate = null

#iterator for comparing scene objects in chunks
var sceneScanIterateCompare = null

# initiate scene variables
func _ready():
	randomize()
	self.sceneScanIterate = 0
	self.sceneScanIterateCompare = 0

#iterate a scene search iterator (for avoiding 'for')
func _iterateScanner(scanIterator,maxValue):
	scanIterator += 1
	if(scanIterator > maxValue):
		scanIterator = 0
	return scanIterator

#get the distance between two objects
func _getDistance(firstObject, secondObject):
	return firstObject.get_global_transform().origin.distance_to(secondObject.get_global_transform().origin)
	
#increment rotation degrees
func _incrementRotation(rotationObject,rotX,rotY,rotZ):
	var originalRotation = rotationObject.get("rotation_degrees")
	rotationObject.set("rotation_degrees",Vector3(originalRotation[0]+rotX,originalRotation[1]+rotY,originalRotation[2]+rotZ))
	
#increment rotation degrees with physics
func _incrementPhysRotation(rotationObject,rotX,rotY,rotZ):
	var originalRotation = rotationObject.get("rotation_degrees")
	rotationObject.set("rotation_degrees",Vector3(originalRotation[0]+rotX,originalRotation[1]+rotY,originalRotation[2]+rotZ))

#iterate a look at towards something on an axis
func _lookTowardsIterate(lookObject,targetObject,rotateXAmount,rotateYAmount,rotateZAmount,previousDistance):
	self._incrementRotation(lookObject,1*rotateXAmount,1*rotateYAmount,1*rotateZAmount) #if one way does not bring the aim target closer, go the other way
	if(self._getDistance(lookObject.get_node("aimTarget"),targetObject) > previousDistance):
		self._incrementRotation(lookObject,-2*rotateXAmount,-2*rotateYAmount,-2*rotateZAmount)
	elif(self._getDistance(lookObject.get_node("aimTarget"),targetObject) == previousDistance):
		self._incrementRotation(lookObject,-1*rotateXAmount,-1*rotateYAmount,-1*rotateZAmount)
	return self._getDistance(lookObject.get_node("aimTarget"),targetObject)

#move an object towards another object at a set speed
func _moveTowardsIterate(movingObject,targetObject,moveSpeed):
	var moveAmount = ((movingObject.get_parent().to_local(targetObject.get_global_transform().origin) - movingObject.get_parent().to_local(movingObject.get_global_transform().origin)).normalized())*moveSpeed
	movingObject.set_translation((movingObject.get_translation() + moveAmount))

#move an object towards another one while keeping a distance
func _limitedFollowIterate(movingObject,targetObject,moveSpeed,distanceLimit):
	if(self._getDistance(movingObject,targetObject) > distanceLimit + moveSpeed):
		self._moveTowardsIterate(movingObject,targetObject,moveSpeed)
	elif(self._getDistance(movingObject,targetObject) < distanceLimit - moveSpeed):
		self._moveTowardsIterate(movingObject,targetObject,-moveSpeed)

#add random motion
func _randomOrbitMove(movingObject,previousMoveAmount):
	var newMoveAmount = Vector3(clamp(previousMoveAmount[0] + rand_range(-0.001,0.001),-0.01,0.01),0,previousMoveAmount[2] + clamp(rand_range(-0.001,0.001),-0.01,0.01))
	movingObject.translate_object_local(newMoveAmount)
	return newMoveAmount

#iterate a look at towards something on a generic 6 dof on one axis with physics
func _lookTowardsPhys(lookObject,targetObject,rotateAxis,rotateSpeed,rotateLimit):
#	var physJointObject = lookObject.get_node("controlledPhysJoint") #constraint to alter
	var aimTargetOffsets = [lookObject.get_node("PositiveMeasure"), #checkers for closest rotation direction
							lookObject.get_node("NegativeMeasure")]
	var yawMovement = 0 #how much to move
	rotateAxis = rotateAxis.to_lower()
	#don't move if the distance isn't great enough to do so (avoid shuddering)
	lookObject.set_angular_damp(1)
	var yawDistanceDifference = abs(self._getDistance(aimTargetOffsets[0],targetObject) - self._getDistance(aimTargetOffsets[1],targetObject))
	if(yawDistanceDifference > 0):
		if(self._getDistance(aimTargetOffsets[0],targetObject) > self._getDistance(aimTargetOffsets[1],targetObject)):
			yawMovement = -rotateSpeed*(yawDistanceDifference*10)
		if(self._getDistance(aimTargetOffsets[0],targetObject) < self._getDistance(aimTargetOffsets[1],targetObject)):
			yawMovement = rotateSpeed*(yawDistanceDifference*10)
	if(rotateAxis == "x"):
		lookObject.add_torque(lookObject.transform.basis.x*yawMovement*10)
	elif(rotateAxis == "y"):
		lookObject.add_torque(lookObject.transform.basis.y*yawMovement*10)
	else:
		lookObject.add_torque(lookObject.transform.basis.z*yawMovement*10)

#iterate a look at towards something on a generic 6 dof on one axis with physics
func _lookTowardsPhysConstraint(lookObject,physJointObject,targetObject,rotateAxis,rotateSpeed,rotateLimit):
	var aimTargetOffsets = [lookObject.get_node("PositiveMeasure"), #checkers for closest rotation direction
							lookObject.get_node("NegativeMeasure")]
	var yawMovement = 0 #how much to move
	rotateAxis = rotateAxis.to_lower()
	#don't move if the distance isn't great enough to do so (avoid shuddering)
	var yawDistanceDifference = abs(self._getDistance(aimTargetOffsets[0],targetObject) - self._getDistance(aimTargetOffsets[1],targetObject))
	if(yawDistanceDifference > 0.1):
		if(self._getDistance(aimTargetOffsets[0],targetObject) > self._getDistance(aimTargetOffsets[1],targetObject)):
			yawMovement = -rotateSpeed*(yawDistanceDifference*10)
		if(self._getDistance(aimTargetOffsets[0],targetObject) < self._getDistance(aimTargetOffsets[1],targetObject)):
			yawMovement = rotateSpeed*(yawDistanceDifference*10)
	physJointObject.set("angular_limit_" + rotateAxis + "/upper_angle",clamp(physJointObject.get("angular_limit_" + rotateAxis + "/upper_angle")+yawMovement,-rotateLimit,rotateLimit))
	physJointObject.set("angular_limit_" + rotateAxis + "/lower_angle",clamp(physJointObject.get("angular_limit_" + rotateAxis + "/lower_angle")+yawMovement,-rotateLimit,rotateLimit))

#iterate a move towards something
func _moveTowardsPhys(movingObject,targetObject,moveSpeed,maxTargetCloseness,maxMoveDistance):
#	var physJointObject = movingObject.get_node("controlledPhysJoint") #constraint to alter
	var moveAmount = (targetObject.get_global_transform().origin - movingObject.get_global_transform().origin).normalized()*moveSpeed
#	var movementAxes = ["x","y","z"]
	var objectDistance = self._getDistance(movingObject,targetObject)
	var moveDistanceRemaining = clamp(objectDistance-maxTargetCloseness,-maxMoveDistance,maxMoveDistance)*2
	movingObject.set_linear_velocity(movingObject.get_linear_velocity()*0)
	if(objectDistance > maxTargetCloseness):
		movingObject.set_axis_velocity(moveAmount*moveDistanceRemaining)
	elif(objectDistance < maxTargetCloseness*0.5):
		movingObject.set_axis_velocity(-moveAmount*moveDistanceRemaining)
		

#iterate a move towards something using constraint limits
func _moveTowardsPhysConstraint(movingObject,physJointObject,targetObject,moveSpeed,maxTargetCloseness,maxMoveDistance):
	var moveAmount = -((movingObject.to_local(targetObject.get_global_transform().origin) - movingObject.to_local(movingObject.get_global_transform().origin)).normalized())*moveSpeed
	var moveDistanceRemaining = clamp(self._getDistance(movingObject,targetObject)-maxTargetCloseness,-moveSpeed,moveSpeed)
	var movementAxes = ["x","y","z"]
	for movementAxis in range(0,len(movementAxes)):
		#clamp speeds
		moveAmount[movementAxis] = clamp(moveAmount[movementAxis],-maxMoveDistance,maxMoveDistance)
		physJointObject.set("linear_limit_" + movementAxes[movementAxis] + "/upper_distance",
						clamp((physJointObject.get("linear_limit_" + movementAxes[movementAxis] + "/upper_distance"))
						+(moveAmount[movementAxis]*moveDistanceRemaining),-maxMoveDistance,maxMoveDistance))
		physJointObject.set("linear_limit_" + movementAxes[movementAxis] + "/lower_distance",
						clamp((physJointObject.get("linear_limit_" + movementAxes[movementAxis] + "/lower_distance"))
						+(moveAmount[movementAxis]*moveDistanceRemaining),-maxMoveDistance,maxMoveDistance))

	
#iterate a movement cycle using constraint limits
func _moveCyclePhysConstraint(moveCyclesDictionary,movingObject,physJointObject,moveCycleName,moveSpeed,maxTargetCloseness,maxMoveDistance,moveCycleDirection):
	if not(movingObject.has_meta("moveCycleStepCurrent")): #set up step iteration
		movingObject.set_meta("moveCycleStepCurrent",0)
		movingObject.set_meta("moveCycleStepNext",0)
		movingObject.set_meta("moveCycleDelayCurrent",0)
	var moveFreeze = false
	if not(movingObject.has_meta("moveFreeze")): #stop the object from progressing movement if it is marked to do so (for holding things)
		movingObject.set_meta("moveFreeze",false)
	moveFreeze = movingObject.get_meta("moveFreeze")
	if(moveFreeze == false):
		movingObject.set_meta("moveCycleStepCurrent",movingObject.get_meta("moveCycleStepNext"))
		var partCyclePointsArray = moveCyclesDictionary[moveCycleName][movingObject.name]
		var stepObject = partCyclePointsArray[clamp(movingObject.get_meta("moveCycleStepCurrent"),0,partCyclePointsArray.size()-1)]
		if(stepObject != null):
			self._moveTowardsPhysConstraint(movingObject,physJointObject,stepObject,moveSpeed,maxTargetCloseness,maxMoveDistance)
			if(movingObject.get_meta("moveCycleDelayCurrent") == 0): #if timer hit to move to next point
				var nextMoveStep = movingObject.get_meta("moveCycleStepCurrent")
				if(moveCycleDirection == "backwards"):
					nextMoveStep -= 1
					if(nextMoveStep < 0):
						nextMoveStep = partCyclePointsArray.size()-1
					movingObject.set_meta("moveCycleStepNext",nextMoveStep) #use next backwards point
				else:
					nextMoveStep += 1
					if(nextMoveStep > partCyclePointsArray.size()-1):
						nextMoveStep = 0
					movingObject.set_meta("moveCycleStepNext",nextMoveStep) #use next forwards point
			movingObject.set_meta("moveCycleDelayCurrent",movingObject.get_meta("moveCycleDelayCurrent")+1)
			#cycle naming format is partname_currentstep_nextstep_previousstep
			if(movingObject.get_meta("moveCycleDelayCurrent") > movingObject.get_meta("moveCycleDelayMax")):
				movingObject.set_meta("moveCycleDelayCurrent",0)
			
#animate a move cycle which slows to a rest position when a reference object reaches a target
func _moveCycleByDistance(moveCyclesDictionary,movingPart,maxReferenceObjectCloseness,maxPartTargetCloseness,moveCycleName,moveLimit,moveSpeed,physJointObject,currentDistance,reverseMoveTime):
	if(reverseMoveTime == 0):
		self._moveCyclePhysConstraint(moveCyclesDictionary,movingPart,physJointObject,moveCycleName,moveSpeed*clamp(currentDistance*0.1,0.2,1),maxPartTargetCloseness,moveLimit,"forwards")
	elif(reverseMoveTime > 0):
		self._moveCyclePhysConstraint(moveCyclesDictionary,movingPart,physJointObject,moveCycleName,moveSpeed*clamp(currentDistance*0.1,0.2,1),maxPartTargetCloseness,moveLimit,"backwards")
#	else: #move back to rest position, no longer required because rest is handled by close actions or far actions
#		self._moveTowardsPhysConstraint(movingPart,physJointObject,restPositionObject,moveSpeed*0.5,0.2,moveLimit)

#attach to objects, for things like grabbing or equipping
func _dynamicAttachmentUpdate(attachJoint,attachTriggerRay,attachingPart,freezeMovement,enableAttach,attachTimeMax,passiveAttachTimeMax,reattachDelayMax):
	if not (attachingPart.has_meta("attachTime")): #make attachments last a finite time
		attachingPart.set_meta("attachTime",attachTimeMax)
	if not (attachingPart.has_meta("reattachDelay")): #wait for some time before making a new attachment
		attachingPart.set_meta("reattachDelay",0)
	if not (attachingPart.has_meta("isAttached")): #boolean for if the constraint is activated on the attaching object
		attachingPart.set_meta("isAttached",false)
	if(attachingPart.get_meta("reattachDelay") > 0 and attachingPart.get_meta("isAttached") == false): #don't do any attaching if there is a delay on attaching
		attachingPart.set_meta("reattachDelay",attachingPart.get_meta("reattachDelay")-1)
	else:
		var freezingPart = attachingPart 
		if(freezingPart.get_parent().has_node(freezingPart.name + "Helper")): #determine if this is the part to apply motion freezing to
			freezingPart = freezingPart.get_parent().get_node(freezingPart.name + "Helper")
		var movementAxes = ["x","y","z"] #axes for enabling and disabling joints
		var freezingPartPhysJoint = freezingPart.get_node("physJoint")
		if(attachingPart.get_meta("attachTime") > 0 and attachingPart.get_meta("isAttached") == true): #count down attach time while attached
			attachingPart.set_meta("attachTime",attachingPart.get_meta("attachTime")-1)
		if((enableAttach == false or attachingPart.get_meta("attachTime") == 0) and attachingPart.get_meta("isAttached") == true): #set to drop or not attach
			print("not attached!!")
			freezingPart.set_meta("moveFreeze",false) #unfreeze path following motion
			for movementAxis in range(0,len(movementAxes)):
				attachJoint.set("linear_limit_" + movementAxes[movementAxis] + "/enabled",false) #turn off the joint
				attachJoint.set("angular_limit_" + movementAxes[movementAxis] + "/enabled",false)
#				freezingPartPhysJoint.set_meta("constraintMoveBuffer",1) #add buffer to smooth transition
				freezingPartPhysJoint.set("linear_limit_" + movementAxes[movementAxis] + "/enabled",true) #make sure that the phys joint is back on
				freezingPartPhysJoint.set("angular_limit_" + movementAxes[movementAxis] + "/enabled",true)
			if(attachJoint.has_meta("currentAttachedObject")): #
				var lastAttachedObject = attachJoint.get_meta("currentAttachedObject")
				if (lastAttachedObject.has_meta("attachedObjectCount")):
					lastAttachedObject.set_meta("attachedObjectCount",lastAttachedObject.get_meta("attachedObjectCount")-1)
			attachJoint.set("nodes/node_b","NoAttachment")#change so that re-attaching to the previous item is possible
			attachingPart.set_meta("attachTime",attachTimeMax) #reset attach time for new attachment
			attachingPart.set_meta("isAttached",false)
		elif(attachTriggerRay.is_colliding() == true): #set to attach to new things
			var attachObject = attachTriggerRay.get_collider()
			if not(attachJoint.get("nodes/node_b") == attachObject.get_path()): #if the collision has been set already, don't set it again
				if not(attachObject.get_parent() == attachingPart.get_parent()): #don't attach to self
					print("setting attach joint")
					#mark each object with a count of the number of constraints it has
					#so that there can only be one object forcing it around and other objects must follow only
					if not (attachObject.has_meta("attachedObjectCount")):
						attachObject.set_meta("attachedObjectCount",0)
					#don't try to move it if it has a joint already or is static
					if((attachObject.has_node("physJoint") or attachObject.get("mode") == 1) and attachObject.get_meta("attachedObjectCount") == 0):
						attachObject.set_meta("attachedObjectCount",1)
					#'Helper' in a name indicates that this object is a translating object with a chain of physics objects connecting it to something
					#so that disabling its physjoint will allow it to hang free without breaking
					if(attachObject.get_meta("attachedObjectCount") > 0 and "Helper" in freezingPart.name): #if grabbing something with existing attachments, become a passive constraint
						for movementAxis in range(0,len(movementAxes)):
							freezingPartPhysJoint.set("linear_limit_" + movementAxes[movementAxis] + "/enabled",false)
							freezingPartPhysJoint.set("angular_limit_" + movementAxes[movementAxis] + "/enabled",false)
						attachingPart.set_meta("attachTime",passiveAttachTimeMax) #a different attach time may be needed in this passive attach mode
						#reduce the attach time further if it's static
						if(attachObject.get("mode") == 1):
							attachingPart.set_meta("attachTime",attachingPart.get_meta("attachTime")*0.1)
					freezingPart.set_meta("moveFreeze",freezeMovement) #freeze the path following of an object if needed
					attachJoint.set("nodes/node_b",attachObject.get_path())
					attachJoint.set_meta("currentAttachedObject",attachObject) #keep a reference to the object itself for clearing constraint later
					for movementAxis in range(0,len(movementAxes)):
						attachJoint.set("linear_limit_" + movementAxes[movementAxis] + "/enabled",true)
						attachJoint.set("angular_limit_" + movementAxes[movementAxis] + "/enabled",true)
					attachingPart.set_meta("isAttached",true)
					attachingPart.set_meta("reattachDelay",reattachDelayMax) #wait before making a new attachment if this one is cancelled

#turn off visibility of one mesh and turn on visibility of another
func _meshVisibilitySwap(swappingPart,newVisibleMesh):
	swappingPart.get_meta("currentDisplayedMesh").set_visible(false)
	newVisibleMesh.set_visible(true)
	swappingPart.set_meta("currentDisplayedMesh",newVisibleMesh)

#animate mesh changes using mesh visibility
func _animateMeshSwap(swappingPart,meshSwapType,emotionValue,specificMeshObject):
	var isAttachingMesh = false #handle attaching mesh variations
	if (meshSwapType == "attachMesh" or meshSwapType == "expressiveMeshAttach"):
		isAttachingMesh = true
	if (meshSwapType == "expressiveMeshAttach"): #handle expressive mesh and attaching expressive mesh similarly
		meshSwapType = "expressiveMesh"
	if(swappingPart.get_children() != []): #if there are meshes there
		if not (swappingPart.has_meta("currentDisplayedMesh")): #make attachments last a finite time
			for meshToHide in swappingPart.get_children():
				meshToHide.set_visible(false)
			swappingPart.set_meta("currentDisplayedMesh",swappingPart.get_children()[0])
			swappingPart.get_children()[0].set_visible(true)
		if not (swappingPart.has_meta("previousMeshSwapType")): #for reverting from specific mesh swaps to automatic ones
			swappingPart.set_meta("previousMeshSwapType","NONE")
			swappingPart.set_meta("previousMeshObject",null)
		if(meshSwapType != "specificMesh" and swappingPart.get_meta("previousMeshSwapType") != meshSwapType): 
			swappingPart.set_meta("previousMeshSwapType",meshSwapType)
			swappingPart.set_meta("previousMeshObject",swappingPart.get_meta("currentDisplayedMesh"))
		if(meshSwapType == "expressiveMesh"): #meshes which change according to emotion value
			if(swappingPart.has_node("mesh_emotion" + str(emotionValue))): 
				self._meshVisibilitySwap(swappingPart,swappingPart.get_node("mesh_emotion" + str(emotionValue)))
		if(meshSwapType == "expressiveMeshBlinking"): #meshes which change according to emotion value and randomly 'blink'
			var swapMeshName = "mesh_emotion" + str(emotionValue) #include blinking
			if not (swappingPart.has_meta("meshBlinkDelayTime") and swappingPart.has_meta("meshBlinkOnTime")):
				swappingPart.set_meta("meshBlinkDelayTime",500) #set up blink meta values if not already set up
				swappingPart.set_meta("meshBlinkOnTime",10)
			if(swappingPart.get_meta("meshBlinkDelayTime") == 0): #if the delay has passed between blinks, switch mesh to blinking version
				swapMeshName = "mesh_emotion" + str(emotionValue) + "_blink"
				if(swappingPart.get_meta("meshBlinkOnTime") == 0): #if the delay for keeping the blink on has passed, return to non blinking and start timers again
					swapMeshName = "mesh_emotion" + str(emotionValue)
					swappingPart.set_meta("meshBlinkDelayTime",int(rand_range(10,500)))
					swappingPart.set_meta("meshBlinkOnTime",int(rand_range(5,10)))
				else: #decrement blinking on timer
					swappingPart.set_meta("meshBlinkOnTime",swappingPart.get_meta("meshBlinkOnTime")-1)
			else: #decrement time between blinks timer
				swappingPart.set_meta("meshBlinkDelayTime",swappingPart.get_meta("meshBlinkDelayTime")-1)
			if(swappingPart.has_node(swapMeshName)):  #apply chosen mesh, blinking or unblinking
				if(swappingPart.get_meta("previousMeshObject") != swappingPart.get_node(swapMeshName)):
					self._meshVisibilitySwap(swappingPart,swappingPart.get_node(swapMeshName))	
					swappingPart.set_meta("previousMeshObject",swappingPart.get_node(swapMeshName))
		elif(meshSwapType == "randomInitialMesh"):
			if not (swappingPart.has_meta("isInitialMeshChosen")):
				swappingPart.set_meta("isInitialMeshChosen",false)
			if(swappingPart.get_meta("isInitialMeshChosen") == false):
				for meshToHide in swappingPart.get_children():
					meshToHide.set_visible(false)
				var pickedRandomMesh = swappingPart.get_children()[randi() % swappingPart.get_children().size()]
				self._meshVisibilitySwap(swappingPart,pickedRandomMesh)
				swappingPart.set_meta("isInitialMeshChosen",true)
		elif(meshSwapType == "specificMesh"): #switch to a specific mesh
			if(specificMeshObject != null):
				if(specificMeshObject.is_visible() == false):
					print("specific visibility swap")
					self._meshVisibilitySwap(swappingPart,specificMeshObject)
					swappingPart.set_meta("previousMeshObject",specificMeshObject)
					
		#swap to an attached mesh when the mesh attaches to something, 
		#overrides other mesh swaps when enabled
		if(isAttachingMesh == true): 
			if not (swappingPart.get_parent().has_meta("isAttached")):
				swappingPart.get_parent().set_meta("isAttached",false)
			if(swappingPart.get_parent().get_meta("isAttached") == true):
				if(swappingPart.has_node("mesh_attached")):
					self._meshVisibilitySwap(swappingPart,swappingPart.get_node("mesh_attached"))
			elif(meshSwapType == "attachMesh"): #if the mesh swap is for attach only, revert to neutral pose when not attached
				if(swappingPart.has_node("mesh_unattached")): 
					self._meshVisibilitySwap(swappingPart,swappingPart.get_node("mesh_unattached"))
		

#get an action suitable for the a specific character state
func _getActionResponseArray(responseDictionary,triggerPartName,emotionValue):
	var actionDefinition = null
	var randomActionNumber = null
	if not(emotionValue in responseDictionary[triggerPartName]): #set up a generic emotion response if a specific one is not available
		emotionValue = 3
	randomActionNumber = randi() % responseDictionary[triggerPartName][emotionValue].size()
	actionDefinition = responseDictionary[triggerPartName][emotionValue][randomActionNumber]
	return [actionDefinition,triggerPartName,emotionValue,randomActionNumber]

func _updateResponseAction(currentObject,focusSubTarget,responseDictionary,responseTypeName,emotionValue):
	if(currentObject.focusSubTarget != null):
		var actionDefinition = null #the action that will be chosen for this response type
		if(currentObject.focusSubTarget.name in responseDictionary): #set up a specific target response
			actionDefinition = self._getActionResponseArray(responseDictionary,focusSubTarget.name,emotionValue)
		else: #set up a generic target response
			actionDefinition = self._getActionResponseArray(responseDictionary,"ANY",emotionValue)
		for partSettingsArray in actionDefinition[0]:
			var settingsChangeName = "em" + str(actionDefinition[2]) + "trpt" + str(actionDefinition[1]) + "ran" + str(actionDefinition[3])
			var settingsTargetPart = partSettingsArray[0]
			var newRandomActionCooldownMax = partSettingsArray[1]
			var targetPartMetaArray = partSettingsArray[2]
			if not(settingsTargetPart.has_meta("lastMetaChangeName")): #prevent repeated changing of the same setting
				settingsTargetPart.set_meta("lastMetaChangeName","INITIAL")
			if not(settingsTargetPart.has_meta("randomActionCooldown")): #slow down randomisation of actions
				settingsTargetPart.set_meta("randomActionCooldown",0)
			if not(settingsTargetPart.has_meta("lastMetaChangeTrigger")): #for determining when a meta change will be a randomisation
				settingsTargetPart.set_meta("lastMetaChangeTrigger","INITIAL")
			var canUpdateMeta = true #if the update is going to be a randomisation, slow down the frequency of randomisation
			if(settingsTargetPart.get_meta("lastMetaChangeTrigger") == responseTypeName + str(actionDefinition[1]) + str(actionDefinition[2])):
				if(settingsTargetPart.get_meta("randomActionCooldown") > 0):
					canUpdateMeta = false
					settingsTargetPart.set_meta("randomActionCooldown",settingsTargetPart.get_meta("randomActionCooldown")-1)
				elif(settingsTargetPart.has_meta("randomActionCooldownMax")):
					settingsTargetPart.set_meta("randomActionCooldown",settingsTargetPart.get_meta("randomActionCooldownMax"))
			if(canUpdateMeta == true):
				#print("reached meta settings change for " + currentObject.name)
				if not(settingsTargetPart.get_meta("lastMetaChangeName") == settingsChangeName):
					for metaValueArray in targetPartMetaArray: #set all meta values using the action definition array
						settingsTargetPart.set_meta(metaValueArray[0],metaValueArray[1])
					#print("changed meta settings for " + currentObject.name)
					settingsTargetPart.set_meta("randomActionCooldownMax",newRandomActionCooldownMax)#update the cooldown value when randomising actions for this part
					settingsTargetPart.set_meta("lastMetaChangeName",settingsChangeName)
					settingsTargetPart.set_meta("lastMetaChangeTrigger",responseTypeName + str(actionDefinition[1]) + str(actionDefinition[2]))

# process scene
func _physics_process(delta):
	#object for performing comparisons
	var currentCompareObject = self.get_children()[sceneScanIterate]
	
	#second scan to compare scene objects
	var randomSceneRangeMax = int(rand_range(1,50))
	if(randomSceneRangeMax > len(self.get_children())):
			randomSceneRangeMax = len(self.get_children())
	for sceneObjectNumber in range(0,randomSceneRangeMax):
		var currentObject = self.get_children()[sceneObjectNumber]
		#set a focus on a new object if the focus time for an old object has run out and the object is close enough
		if("targetDistanceLimit" in currentObject and "targetDistanceReference" in currentObject):
			if(self._getDistance(currentCompareObject,currentObject.targetDistanceReference) < currentObject.targetDistanceLimit):
				if("focusTarget" in currentObject and "focusTime" in currentObject):
					#if the current focus object has been looked at enough, it isnt the self object and it has some inner parts to focus on, focus on it
					if(currentObject.focusTime <= 0 and currentCompareObject != currentObject and "focusPartList" in currentCompareObject and "obstacleArea" in currentCompareObject):
						currentObject.focusTarget = currentCompareObject
						currentObject.focusTime = int(rand_range(currentObject.focusTimeMax*0.3,currentObject.focusTimeMax))
						print("switched " + currentObject.name + " focus to " + currentObject.focusTarget.name)
						currentObject.focusSubTime = -1 #switching focus needs to reset the sub focus
					else:
						currentObject.focusTime -= 1
		#change emotion value depending on target object
		if("emotionValue" in currentObject and "traitPerceptions" in currentObject and currentObject.focusTarget != null and "emotionChangeCounter" in currentObject and "emotionCounterMax" in currentObject):
			if(currentObject.emotionChangeCounter == 0):
				if("characterTraits" in currentObject.focusTarget):
					var newEmotionValue = 3 
					for otherCharacterTrait in currentObject.focusTarget.characterTraits:
						#multiply the amount by which the other character has a certain trait
						#by the amount by which this character likes or dislikes that trait
						#and add it (or subtract it if negative) to the emotion value which defaults at 3 (neutral)
						newEmotionValue = newEmotionValue + (currentObject.traitPerceptions[otherCharacterTrait[0]] * otherCharacterTrait[1])
					currentObject.emotionValue = clamp(round(newEmotionValue),0,6) #round value
					print(currentObject.name + " changed emotion to " + str(currentObject.emotionValue) + " because of seeing " + currentObject.focusTarget.name)
				currentObject.emotionChangeCounter = currentObject.emotionCounterMax
			else:
				currentObject.emotionChangeCounter -= 1
		if("focusSubTarget" in currentObject and "focusSubTime" in currentObject):
			#quickly change between sub focus objects
			if(currentObject.focusTarget != null):
				if(currentObject.focusSubTime <= 0 and "focusPartList" in currentObject.focusTarget and "obstacleArea" in currentCompareObject):
					currentObject.focusSubTarget = currentObject.focusTarget.focusPartList[randi() % currentObject.focusTarget.focusPartList.size()]
					currentObject.focusSubTime = int(rand_range(currentObject.focusSubTimeMax*0.3,currentObject.focusSubTimeMax))
					#print("switched " + currentObject.name + " sub focus to " + currentObject.focusSubTarget.name)
				else:
					currentObject.focusSubTime -= 1
			#calculate distances
			if(currentObject.focusSubTarget != null):
				currentObject.targetDistance = self._getDistance(currentObject.focusTarget,currentObject.targetDistanceReference)
		
		#change meta settings for nodes for movement and actions occuring near and far from a target
		if("targetDistance" in currentObject and "targetDistanceMaxCloseness" in currentObject and "focusSubTarget" in currentObject):
			if(currentObject.focusSubTarget != null): #if there is a target
				var areaReachedTarget = false
				if("obstacleArea" in currentObject):#if the object can detect that it is bumping into things, step back
					var movementBlockedArea = currentObject.obstacleArea
					var obscuringObjects = movementBlockedArea.get_overlapping_areas()
					if(currentObject.focusTarget.obstacleArea in obscuringObjects): #stop completely if its the target that we have reached
						areaReachedTarget = true
					elif(obscuringObjects != []): #step back if its something in the way
						currentObject.blockedMovementReverseTime = currentObject.blockedReverseTimeMax
					elif(currentObject.blockedMovementReverseTime > 0):
						currentObject.blockedMovementReverseTime -= 1
				if(areaReachedTarget == false): #if the target is far enough away
					if(currentObject.distanceActionTime > 0 and currentObject.targetDistance > currentObject.targetDistanceMaxCloseness * 1.6): #perform a distance action if there is some distance time
						if("farResponseActions" in currentObject):
							self._updateResponseAction(currentObject,currentObject.focusSubTarget,currentObject.farResponseActions,"farResponse",currentObject.emotionValue)
						currentObject.distanceActionTime -= 1
					else: #move to or away from the target if we are not performing a distance action
						if("moveResponseActions" in currentObject):
							self._updateResponseAction(currentObject,currentObject.focusSubTarget,currentObject.moveResponseActions,"moveResponse",currentObject.emotionValue)
				else: #perform close response actions
						currentObject.distanceActionTime = int(rand_range(currentObject.distanceActionTimeMax*0.2,currentObject.distanceActionTimeMax))
						if("closeResponseActions" in currentObject):
							self._updateResponseAction(currentObject,currentObject.focusSubTarget,currentObject.closeResponseActions,"closeResponse",currentObject.emotionValue)

		
		#apply movements to nodes marked with specific meta tags for movement and rotation
		if("movingPartList" in currentObject):
			if not (currentObject.has_meta("isDefaultActionApplied")):
				currentObject.set_meta("isDefaultActionApplied",false)
			if(currentObject.get_meta("isDefaultActionApplied") == false):
				if("defaultInitialAction" in currentObject): #always apply a default action if there is one
					for actionPartArray in currentObject.defaultInitialAction:
						for metaTagLoadout in actionPartArray[1]:
							actionPartArray[0].set_meta(metaTagLoadout[0],metaTagLoadout[1]) #load in meta tags
				currentObject.set_meta("isDefaultActionApplied",true)
			for movingPart in currentObject.movingPartList:
				
				#AIMING AND ROTATION METHODS
				
				if(movingPart.has_meta("aimType")):
					if(movingPart.get_meta("aimType") == "forceFocusTarget" #use forces to face towards focustarget
							and movingPart.has_meta("aimAxis") 
							and movingPart.has_meta("aimSpeed") 
							and movingPart.has_meta("aimLimit") 
							and currentObject.focusSubTarget != null):
						self._lookTowardsPhys(movingPart,
											currentObject.focusSubTarget,
											movingPart.get_meta("aimAxis"),
											movingPart.get_meta("aimSpeed"),
											movingPart.get_meta("aimLimit"))
					elif(movingPart.get_meta("aimType") == "constraintFocusTarget" #use constraint rotation to face towards focustarget
							and movingPart.has_meta("aimAxis") 
							and movingPart.has_meta("aimSpeed") 
							and movingPart.has_meta("aimLimit")  
							and currentObject.focusSubTarget != null):
						var partConstraint = movingPart.get_node("physJoint")
						self._lookTowardsPhysConstraint(movingPart,
											partConstraint,
											currentObject.focusSubTarget,
											movingPart.get_meta("aimAxis"),
											movingPart.get_meta("aimSpeed"),
											movingPart.get_meta("aimLimit"))
											
				#TRANSLATING METHODS
				
				if(movingPart.has_meta("moveType")):
					#move towards the current focus target using forces
					if(movingPart.get_meta("moveType") == "forceFocusTarget" 
							and movingPart.has_meta("moveLimit") 
							and movingPart.has_meta("moveMaxCloseness") 
							and movingPart.has_meta("moveSpeed") 
							and currentObject.focusSubTarget != null):
						self._moveTowardsPhys(movingPart,
											currentObject.focusSubTarget,
											movingPart.get_meta("moveSpeed"),
											movingPart.get_meta("moveMaxCloseness"),
											movingPart.get_meta("moveLimit"))
							
					#move towards a specific target using forces
					elif(movingPart.get_meta("moveType") == "forceTarget" 
							and movingPart.has_meta("moveLimit") 
							and movingPart.has_meta("moveMaxCloseness") 
							and movingPart.has_meta("moveSpeed") 
							and movingPart.has_meta("moveTarget")):
						self._moveTowardsPhys(movingPart,
												movingPart.get_meta("moveTarget"),
												movingPart.get_meta("moveSpeed"),
												movingPart.get_meta("moveMaxCloseness"),
												movingPart.get_meta("moveLimit"))
						
					#move towards the current focus target using constraint limits
					elif(movingPart.get_meta("moveType") == "constraintFocusTarget" 
							and movingPart.has_meta("moveLimit") 
							and movingPart.has_meta("moveMaxCloseness") 
							and movingPart.has_meta("moveSpeed") 
							and movingPart.has_node("physJoint")
							and currentObject.focusSubTarget != null):
							var partConstraint = movingPart.get_node("physJoint")
							self._moveTowardsPhysConstraint(movingPart,
														partConstraint,
														currentObject.focusSubTarget,
														movingPart.get_meta("moveSpeed"),
														movingPart.get_meta("moveMaxCloseness"),
														movingPart.get_meta("moveLimit"))
					#move towards a specific target using constraint limits
					elif(movingPart.get_meta("moveType") == "constraintTarget" 
							and movingPart.has_meta("moveLimit") 
							and movingPart.has_meta("moveMaxCloseness") 
							and movingPart.has_meta("moveSpeed") 
							and movingPart.has_meta("moveTarget")
							and movingPart.has_node("physJoint")):
							var partConstraint = movingPart.get_node("physJoint")
							self._moveTowardsPhysConstraint(movingPart,
														partConstraint,
														movingPart.get_meta("moveTarget"),
														movingPart.get_meta("moveSpeed"),
														movingPart.get_meta("moveMaxCloseness"),
														movingPart.get_meta("moveLimit"))
					#move in a cycle by moving between points
					elif(movingPart.get_meta("moveType") == "constraintMoveCycle" 
							and movingPart.has_meta("moveCycleName") 
							and movingPart.has_meta("moveCycleDelayMax")
							and movingPart.has_meta("moveLimit") 
							and movingPart.has_meta("moveMaxCloseness") 
							and movingPart.has_meta("moveSpeed") 
							and movingPart.has_node("physJoint")):
						self._moveCyclePhysConstraint(currentObject.moveCycleDefinitions,
														movingPart,
														movingPart.get_node("physJoint"),
														movingPart.get_meta("moveCycleName"),
														movingPart.get_meta("moveSpeed"),
														movingPart.get_meta("moveMaxCloseness"),
														movingPart.get_meta("moveLimit"),
														"forwards")
														
					#a movement cycle which changes depending on distance, for things like arm and leg helpers
					elif(movingPart.get_meta("moveType") == "constraintMoveDistanceCycle" 
							and movingPart.has_meta("moveCycleName")
							and movingPart.has_meta("moveCycleDelayMax")
							and movingPart.has_meta("moveLimit") 
							and movingPart.has_meta("moveMaxCloseness") 
							and movingPart.has_meta("moveSpeed")
							and movingPart.has_node("physJoint")
							and currentObject.focusSubTarget != null):
						self._moveCycleByDistance(currentObject.moveCycleDefinitions,
													movingPart,
													currentObject.targetDistanceMaxCloseness,
													movingPart.get_meta("moveMaxCloseness"),
													movingPart.get_meta("moveCycleName"),
													movingPart.get_meta("moveLimit"),
													movingPart.get_meta("moveSpeed"),
													movingPart.get_node("physJoint"),
													currentObject.targetDistance,
													currentObject.blockedMovementReverseTime)
													
				#ATTACHING AND GRABBING METHODS
				
				if(movingPart.has_meta("attachType")):
					#attach to something detected by a ray and allow the part to continue following movement paths
					if(movingPart.get_meta("attachType") == "attachMove"
							and movingPart.has_node("attachJoint/attachRay")):
						self._dynamicAttachmentUpdate(movingPart.get_node("attachJoint"),
													movingPart.get_node("attachRay"),
													movingPart,
													false,
													true,
													movingPart.get_meta("attachActiveTime"),
													movingPart.get_meta("attachPassiveTime"),
													movingPart.get_meta("reattachDelayMax"))
					#attach to something detected by a ray and hold on to it without moving the attacher
					elif(movingPart.get_meta("attachType") == "attachFreeze"
							and movingPart.has_node("attachJoint/attachRay")):
						self._dynamicAttachmentUpdate(movingPart.get_node("attachJoint"),
													movingPart.get_node("attachJoint/attachRay"),
													movingPart,
													true,
													true,
													movingPart.get_meta("attachActiveTime"),
													movingPart.get_meta("attachPassiveTime"),
													movingPart.get_meta("reattachDelayMax"))
					#drop attachments and dont accept new attachments
					elif(movingPart.get_meta("attachType") == "attachCancel"
							and movingPart.has_node("attachJoint/attachRay")):
						self._dynamicAttachmentUpdate(movingPart.get_node("attachJoint"),
													movingPart.get_node("attachJoint/attachRay"),
													movingPart,
													false,
													false,
													movingPart.get_meta("attachActiveTime"),
													movingPart.get_meta("attachPassiveTime"),
													movingPart.get_meta("reattachDelayMax"))
													
				#MESH SWAPPING METHODS
				
				if(movingPart.has_meta("meshSwapType")):
					
					#swap mesh in response to an attachment
					if(movingPart.get_meta("meshSwapType") == "attachMesh"):
						self._animateMeshSwap(movingPart,
												movingPart.get_meta("meshSwapType"),
												currentObject.emotionValue,
												null)
					#mesh swap for emotion numbers which falls back to attach swap when attached
					elif(movingPart.get_meta("meshSwapType") == "expressiveMeshAttach"):
						self._animateMeshSwap(movingPart,
												movingPart.get_meta("meshSwapType"),
												currentObject.emotionValue,
												null)
					#mesh swap for emotion numbers
					elif(movingPart.get_meta("meshSwapType") == "expressiveMesh"):
						self._animateMeshSwap(movingPart,
												movingPart.get_meta("meshSwapType"),
												currentObject.emotionValue,
												null)
					#mesh swap for emotion numbers with blink
					elif(movingPart.get_meta("meshSwapType") == "expressiveMeshBlinking"):
						self._animateMeshSwap(movingPart,
												movingPart.get_meta("meshSwapType"),
												currentObject.emotionValue,
												null)
					#mesh swap for picking a random initial mesh once only
					elif(movingPart.get_meta("meshSwapType") == "randomInitialMesh"):
						self._animateMeshSwap(movingPart,
												movingPart.get_meta("meshSwapType"),
												currentObject.emotionValue,
												null)
					#mesh swap for picking a specific mesh
					elif(movingPart.get_meta("meshSwapType") == "specificMesh"):
						self._animateMeshSwap(movingPart,
												movingPart.get_meta("meshSwapType"),
												currentObject.emotionValue,
												movingPart.get_meta("specificMeshObject"))

		
		self.sceneScanIterateCompare = self._iterateScanner(self.sceneScanIterateCompare,len(self.get_children())-1)
	#iterate scene scan counter
	self.sceneScanIterate = self._iterateScanner(self.sceneScanIterate,len(self.get_children())-1)
