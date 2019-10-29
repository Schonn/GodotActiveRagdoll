extends Spatial

#object variables
var focusPartList = null
#area object for detecting distances to targets or obstructions
var obstacleArea = null
var reachedTargetArea = null

#traits for this character which other characters can react to
var characterTraits = null

#set up object variables
func _ready():
	self.focusPartList = [self.get_node("targetPart"),
						self.get_node("targetPart2"),
						self.get_node("targetPart3"),
						self.get_node("targetPart4")]
	
	self.obstacleArea = self.get_node("targetPart/obstacleTestArea")
	self.reachedTargetArea = self.obstacleArea
	
	self.characterTraits = [ #traits relating to this character and how strong each trait is
								["cold",1],
								["sharp",1]
							]