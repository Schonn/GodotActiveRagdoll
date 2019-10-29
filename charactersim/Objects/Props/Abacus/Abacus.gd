extends Spatial

#object variables
var focusPartList = null
var movingPartList = null
#area object for detecting distances to targets or obstructions
var reachedTargetArea = null

#traits for this character which other characters can react to
var characterTraits = null

#set up object variables
func _ready():
	self.focusPartList = [self.get_node("AbacusBead1"),
							self.get_node("AbacusBead2")]
	self.movingPartList = self.focusPartList #same focus points as moving points
	
	self.reachedTargetArea = self.get_node("AbacusFrame/ReachedTargetArea")
	
	self.characterTraits = [ #traits relating to this character and how strong each trait is
								["hard",0.5],
								["rough",0.5],
								["blue",0.2],
								["green",0.8],
								["rough",0.5],
								["small",0.9],
								["complex",1],
								["subdued",0.6]
							]