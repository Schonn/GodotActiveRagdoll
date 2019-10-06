extends Spatial

#character variables
var focusTarget = null
var focusTime = null
var movingPartList = null
var focusPartList = null
var moveLocomotionList = null

#set up character variables
func _ready():
	self.focusTime = 0
	#list of parts with custom move rules, the first part will be considered a point of reference
	self.movingPartList = 	[self.get_node("Head"),
							self.get_node("Neck"),
							self.get_node("Pelvis"),
							self.get_node("HandLeft"),
							self.get_node("HandRight"),
							self.get_node("FootLeft"),
							self.get_node("FootRight")]
	#list of parts for use by other objects
	self.focusPartList = [self.get_node("Head"),
							self.get_node("Neck"),
							self.get_node("HandLeft"),
							self.get_node("HandRight")]
							
	#initial custom setup for character
	var headPart = self.movingPartList[0]
	headPart.set_meta("aimType","focusTarget")
	headPart.set_meta("aimAxis","y")
	headPart.set_meta("aimSpeed",20)
	headPart.set_meta("aimLimit",100)
	
	var neckPart = self.movingPartList[1]
	neckPart.set_meta("aimType","focusTarget")
	neckPart.set_meta("aimAxis","z")
	neckPart.set_meta("aimSpeed",20)
	neckPart.set_meta("aimLimit",100)
	
#	#handLeft
#	self.movingPartList[3].set_meta("moveType","constraintFocusTarget")
#	self.movingPartList[3].set_meta("moveLimit",3.5)
#	self.movingPartList[3].set_meta("moveSpeed",0.3)
#	self.movingPartList[3].set_meta("moveMaxCloseness",0.2)
#	#handRight
#	self.movingPartList[4].set_meta("moveType","constraintFocusTarget")
#	self.movingPartList[4].set_meta("moveLimit",3)
#	self.movingPartList[4].set_meta("moveSpeed",0.2)
#	self.movingPartList[4].set_meta("moveMaxCloseness",0.4)


#	var handLeftPart = self.movingPartList[3]
#	handLeftPart.set_meta("moveType","forceFocusTarget")
#	handLeftPart.set_meta("moveLimit",100)
#	handLeftPart.set_meta("moveSpeed",1)
#	handLeftPart.set_meta("moveMaxCloseness",0.2)
#
#	var handRightPart = self.movingPartList[4]
#	handRightPart.set_meta("moveType","forceFocusTarget")
#	handRightPart.set_meta("moveLimit",100)
#	handRightPart.set_meta("moveSpeed",1)
#	handRightPart.set_meta("moveMaxCloseness",0.2)

	var footLeftPart = self.movingPartList[5]
	footLeftPart.set_meta("moveType","constraintMoveCycleLocomotion")
	footLeftPart.set_meta("moveCycleObject",self.get_node("Pelvis/moveCycle_WalkNormal"))
	footLeftPart.set_meta("moveCycleStepCurrent",0)
	footLeftPart.set_meta("moveCycleStepNext",0)
	footLeftPart.set_meta("moveCycleDelayCurrent",0)
	footLeftPart.set_meta("moveCycleDelayMax",10)
	footLeftPart.set_meta("moveLimit",100)
	footLeftPart.set_meta("moveSpeed",0.3)
	footLeftPart.set_meta("moveMaxCloseness",0.1)
	footLeftPart.set_meta("moveMaxReferenceCloseness",5) #how close a cycle will bring the body to a target
	
	var footRightPart = self.movingPartList[6]
	footRightPart.set_meta("moveType","constraintMoveCycleLocomotion")
	footRightPart.set_meta("moveCycleObject",self.get_node("Pelvis/moveCycle_WalkNormal"))
	footRightPart.set_meta("moveCycleStepCurrent",0)
	footRightPart.set_meta("moveCycleStepNext",0)
	footRightPart.set_meta("moveCycleDelayCurrent",0)
	footRightPart.set_meta("moveCycleDelayMax",10)
	footRightPart.set_meta("moveLimit",100)
	footRightPart.set_meta("moveSpeed",0.3)
	footRightPart.set_meta("moveMaxCloseness",0.1)
	footRightPart.set_meta("moveMaxReferenceCloseness",5)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
