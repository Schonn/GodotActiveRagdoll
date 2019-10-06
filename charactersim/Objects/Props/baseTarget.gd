extends Spatial

#object variables
var focusPartList = null
#area object for detecting distances to targets or obstructions
var obstacleArea = null

#set up object variables
func _ready():
	self.focusPartList = [self.get_node("targetPart"),
						self.get_node("targetPart2"),
						self.get_node("targetPart3"),
						self.get_node("targetPart4")]
	
	self.obstacleArea = self.get_node("targetPart/obstacleTestArea")
