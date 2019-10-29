extends Spatial

#focus related variables
var focusTarget = null
var focusSubTarget = null
var focusTime = null
var focusTimeMax = null
var focusSubTime = null
var focusSubTimeMax = null

#part list used for applying part actions and defining points that can be focused on
var movingPartList = null
var focusPartList = null

#variables relating to the emotion number line from 0 to 6 where 3 is neutral
#including an array of the character's traits and how strong each trait is (adding to a total of 7)
#and a dictionary of possible traits and how the character percieves those traits (each -1 to 1)
var emotionValue = null
var emotionChangeCounter = null
var emotionCounterMax = null
var characterTraits = null
var traitPerceptions = null
var emotionSoundSourceObject = null #where to find the spatial nodes which will contain emotion sounds

#dictionary of points for animation cycles
var moveCycleDefinitions = null

#regarding distances to focused object for movement and distance actions
var targetDistance = null
var targetDistanceMaxCloseness = null #the closest a target can be
var targetDistanceReference = null
var distanceActionTime = null
var distanceActionTimeMax = null
var targetDistanceLimit = null #the furthest a target can be

#area object for detecting distances to targets or obstructions
var obstacleArea = null
var reachedTargetArea = null

#for getting around obstacles
var blockedReverseTimeMax = null
var blockedMovementReverseTime = null

#actions for responding to what the character sees
var moveResponseActions = null
var closeResponseActions = null
var farResponseActions = null
var defaultInitialAction = null

#set up character variables
func _ready():
	self.focusTime = 0 #time remaining to keep focus on target as a whole
	self.focusSubTime = 0 #time remaining to keep focus on a smaller part of a target
	self.focusTimeMax = 2000 #time remaining to keep focus on target as a whole
	self.focusSubTimeMax = 200 #time remaining to keep focus on a smaller part of a target
	
	self.emotionValue = 3 #emotion value from 0 to 6, starting at middle of 3
	self.emotionChangeCounter = 0
	self.emotionCounterMax = 200
	
	self.emotionSoundSourceObject = self.get_node("Head")
	
	self.characterTraits = [ #traits relating to this character and how strong each trait is
								["slimy",0.5],
								["warm",1],
								["smelly",0.3],
								["blue",1],
								["small",0.5],
								["salty",0.5]
							]
	
	#how the character percieves each possible trait where -1 is disline, 0 is neutral and 1 is like
	self.traitPerceptions = {"soft":1,
							"slimy":0.6,
							"hard":0.3,
							"sharp":1,
							"warm":1,
							"cool":1,
							"cold":-1,
							"hot":-0.3,
							"fresh":1,
							"shiny":1,
							"rough":1,
							"smooth":0,
							"lumpy":-0.3,
							"aromatic":0.6,
							"smelly":-1,
							"red":0,
							"blue":0,
							"green":0.6,
							"yellow":0,
							"orange":0,
							"purple":0,
							"white":0,
							"black":0,
							"brown":0.6,
							"silver":1,
							"gold":1,
							"grey":0,
							"bristly":0.6,
							"fluffy":1,
							"tough":1,
							"thin":1,
							"hairy":1,
							"sweet":1,
							"sour":-0.6,
							"bitter":-1,
							"salty":-0.6,
							"savory":0,
							"big":1,
							"small":0,
							"metallic":1,
							"sticky":1,
							"tall":1,
							"short":0,
							"long":0.6,
							"bright":-0.6,
							"dark":1,
							"loud":1,
							"quiet":-0.6,
							"simple":0,
							"complex":1,
							"wet":-0.3,
							"damp":-1,
							"dry":1,
							"damaged":-0.3,
							"distorted":-0.3,
							"clean":1,
							"dirty":-1,
							"exotic":1,
							"rustic":1,
							"vibrant":0,
							"subdued":0,
							"neat":1,
							"messy":-0.6}
	
	self.distanceActionTimeMax = 1000 #maximum possible time to play the distance action 
	self.distanceActionTime = int(rand_range(self.distanceActionTimeMax*0.2,self.distanceActionTimeMax)) #delay to allow character to make a distance action when spotting something before moving to it

	#node for comparing distances between this object and others
	self.targetDistanceReference = self.get_node("Pelvis")
	self.targetDistanceMaxCloseness = 8
	self.targetDistanceLimit = 50
	
	#obstacle avoidance
	self.blockedReverseTimeMax = 200
	self.blockedMovementReverseTime = 0 #current counter for stepping back before stepping forwards again
	self.obstacleArea = self.get_node("Pelvis/obstacleTestArea")
	self.reachedTargetArea = self.obstacleArea
	
	#list of parts to be iterated through to apply move rules, rules won't be applied unless the object is listed here
	self.movingPartList = 	[self.get_node("Head"),
							self.get_node("Neck"),
							self.get_node("Chest"),
							self.get_node("HandLeftHelper"),
							self.get_node("HandRightHelper"),
							self.get_node("FootLeftHelper"),
							self.get_node("FootRightHelper"),
							self.get_node("GyroBottom"),
							self.get_node("HandLeft"),
							self.get_node("HandRight"),
							self.get_node("Head/meshes_default"),
							self.get_node("Head/meshes_startrandom"),
							self.get_node("HandLeft/meshes_default"),
							self.get_node("HandRight/meshes_default")]
	#list of parts for use by other objects
	self.focusPartList = [self.get_node("Head"),
							self.get_node("Neck"),
							self.get_node("HandLeft"),
							self.get_node("HandRight")]
							
							
	#definitions of point loops for motion cycles
	self.moveCycleDefinitions = {"walkNormal":{
												"FootLeftHelper":[
															self.get_node("Pelvis/moveCycle_WalkNormal/FootLeftHelper0"),
															self.get_node("Pelvis/moveCycle_WalkNormal/FootLeftHelper1"),
															self.get_node("Pelvis/moveCycle_WalkNormal/FootLeftHelper2"),
															self.get_node("Pelvis/moveCycle_WalkNormal/FootLeftHelper3")
															],
												"FootRightHelper":[
															self.get_node("Pelvis/moveCycle_WalkNormal/FootRightHelper0"),
															self.get_node("Pelvis/moveCycle_WalkNormal/FootRightHelper1"),
															self.get_node("Pelvis/moveCycle_WalkNormal/FootRightHelper2"),
															self.get_node("Pelvis/moveCycle_WalkNormal/FootRightHelper3")
															],
												"HandLeftHelper":[
															self.get_node("Pelvis/moveCycle_WalkNormal/HandLeftHelper0"),
															self.get_node("Pelvis/moveCycle_WalkNormal/HandLeftHelper1"),
															self.get_node("Pelvis/moveCycle_WalkNormal/HandLeftHelper2"),
															self.get_node("Pelvis/moveCycle_WalkNormal/HandLeftHelper1")
															],
												"HandRightHelper":[
															self.get_node("Pelvis/moveCycle_WalkNormal/HandRightHelper0"),
															self.get_node("Pelvis/moveCycle_WalkNormal/HandRightHelper1"),
															self.get_node("Pelvis/moveCycle_WalkNormal/HandRightHelper2"),
															self.get_node("Pelvis/moveCycle_WalkNormal/HandRightHelper1")
															]
											},
								"walkStrafeLeft":{
												"FootLeftHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootLeftHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootLeftHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootLeftHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootLeftHelper3")
															],
												"FootRightHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootRightHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootRightHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootRightHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/FootRightHelper3")
															],
												"HandLeftHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandLeftHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandLeftHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandLeftHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandLeftHelper1")
															],
												"HandRightHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandRightHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandRightHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandRightHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeLeft/HandRightHelper1")
															]
											},
								"walkStrafeRight":{
												"FootLeftHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootLeftHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootLeftHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootLeftHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootLeftHelper3")
															],
												"FootRightHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootRightHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootRightHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootRightHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/FootRightHelper3")
															],
												"HandLeftHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandLeftHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandLeftHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandLeftHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandLeftHelper1")
															],
												"HandRightHelper":[
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandRightHelper2"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandRightHelper1"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandRightHelper0"),
															self.get_node("Pelvis/moveCycle_WalkStrafeRight/HandRightHelper1")
															]
											},
								"standIdle":{
												"FootLeftHelper":[
															self.get_node("Pelvis/moveCycle_StandIdle/FootLeftHelper0"),
															self.get_node("Pelvis/moveCycle_StandIdle/FootLeftHelper1")
															],
												"FootRightHelper":[
															self.get_node("Pelvis/moveCycle_StandIdle/FootRightHelper0"),
															self.get_node("Pelvis/moveCycle_StandIdle/FootRightHelper1")
															],
												"HandLeftHelper":[
															self.get_node("Pelvis/moveCycle_StandIdle/HandLeftHelper0"),
															self.get_node("Pelvis/moveCycle_StandIdle/HandLeftHelper1")
															],
												"HandRightHelper":[
															self.get_node("Pelvis/moveCycle_StandIdle/HandRightHelper0"),
															self.get_node("Pelvis/moveCycle_StandIdle/HandRightHelper1")
															]
											},
								"farWave":{
												"HandLeftHelper":[
															self.get_node("Head/moveCycle_FarWave/HandLeftHelper0"),
															self.get_node("Head/moveCycle_FarWave/HandLeftHelper1"),
															self.get_node("Head/moveCycle_FarWave/HandLeftHelper2"),
															self.get_node("Head/moveCycle_FarWave/HandLeftHelper1")
															],
												"HandRightHelper":[
															self.get_node("Head/moveCycle_FarWave/HandRightHelper0")
															]
											}
								}
								

	
	#quick loadouts for common action settings
	var quickActionLoadouts = {"walkNormalLimbs":[ 
													["moveType","constraintMoveDistanceCycle"],
													["moveCycleName","walkNormal"], #name in move cycle dictionary
													["moveCycleDelayMax",15],
													["moveLimit",100],
													["moveSpeed",0.25],
													["moveMaxCloseness",0.1]
												],
								"walkStrafeLeftLimbs":[ 
													["moveType","constraintMoveDistanceCycle"],
													["moveCycleName","walkStrafeLeft"],
													["moveCycleDelayMax",15],
													["moveLimit",100],
													["moveSpeed",0.25],
													["moveMaxCloseness",0.1]
												],
								"walkStrafeRightLimbs":[ 
													["moveType","constraintMoveDistanceCycle"],
													["moveCycleName","walkStrafeRight"],
													["moveCycleDelayMax",15],
													["moveLimit",100],
													["moveSpeed",0.25],
													["moveMaxCloseness",0.1]
												],
								"standIdleLimbs":[ 
													["moveType","constraintMoveCycle"],
													["moveCycleName","standIdle"],
													["moveCycleDelayMax",40],
													["moveLimit",100],
													["moveSpeed",0.1],
													["moveMaxCloseness",0.1]
												],
								"farWaveArms":[ 
													["moveType","constraintMoveCycle"],
													["moveCycleName","farWave"],
													["moveCycleDelayMax",15],
													["moveLimit",100],
													["moveSpeed",0.25],
													["moveMaxCloseness",0.1]
												],
								"yawAimPart":[ 
													["aimType","constraintFocusTarget"],
													["aimAxis","y"],
													["aimSpeed",1],
													["aimLimit",40]
												],
								"pitchAimPart":[ 
													["aimType","constraintFocusTarget"],
													["aimAxis","x"],
													["aimSpeed",1],
													["aimLimit",40]
												],
								"pitchAimPartSubtle":[ 
													["aimType","constraintFocusTarget"],
													["aimAxis","x"],
													["aimSpeed",0.1],
													["aimLimit",3]
												],
								"gyroAim":[ 
													["moveType","forceTarget"],
													["moveLimit",100],
													["moveSpeed",1],
													["moveMaxCloseness",0],
													["moveTarget",self.get_node("Pelvis")],
													["aimType","forceFocusTarget"],
													["aimAxis","y"],
													["aimSpeed",1000],
													["aimLimit",40]
												],
								"attachFreeze":[ 
													["attachType","attachFreeze"],
													["attachActiveTime",2000],
													["attachPassiveTime",500],
													["reattachDelayMax",500]
												],
								"attachCancel":[ 
													["attachType","attachCancel"],
													["attachActiveTime",2000],
													["attachPassiveTime",500],
													["reattachDelayMax",500]
												],
								"meshSwapAttach":[ 
													["meshSwapType","attachMesh"]
												],
								"meshSwapExpressionBlinking":[ 
													["meshSwapType","expressiveMeshBlinking"]
												],
								"meshSwapStartRandom":[ 
													["meshSwapType","randomInitialMesh"]
												],
								"meshSwapWave":[ 
													["meshSwapType","specificMesh"],
													["specificMeshObject",self.get_node("HandLeft/meshes_default/mesh_wave")]
												]
								}
	
	#an initial action to run before running any other actions
	self.defaultInitialAction = [
									[ #node to update and action variable array
										self.get_node("Head"),quickActionLoadouts["yawAimPart"]
									],
									[
										self.get_node("Head/meshes_default"),quickActionLoadouts["meshSwapExpressionBlinking"]
									],
									[
										self.get_node("Head/meshes_startrandom"),quickActionLoadouts["meshSwapStartRandom"]
									],
									[ 
										self.get_node("Neck"),quickActionLoadouts["pitchAimPart"]
									],
									[ 
										self.get_node("Chest"),quickActionLoadouts["pitchAimPartSubtle"]
									],
									[ 
										self.get_node("GyroBottom"),quickActionLoadouts["gyroAim"]
									],
									[ 
										self.get_node("HandRight"),quickActionLoadouts["attachFreeze"]
									],
									[ 
										self.get_node("HandLeft"),quickActionLoadouts["attachFreeze"]
									],
									[ 
										self.get_node("HandRight/meshes_default"),quickActionLoadouts["meshSwapAttach"]
									],
									[ 
										self.get_node("HandLeft/meshes_default"),quickActionLoadouts["meshSwapAttach"]
									],
									[ 
										self.get_node("FootLeftHelper"),quickActionLoadouts["standIdleLimbs"]
									],
									[ 
										self.get_node("FootRightHelper"),quickActionLoadouts["standIdleLimbs"]
									],
									[ 
										self.get_node("HandRightHelper"),quickActionLoadouts["standIdleLimbs"]
									],
									[ 
										self.get_node("HandLeftHelper"),quickActionLoadouts["standIdleLimbs"]
									]
								]
	
	#list of actions to use when moving towards or away from a target
	self.moveResponseActions = 	{"ANY":
								{3:
									[ #move action for any subtarget at emotion value of 3
										[ #random variant 0 of action
											[ #name for this action, node to update, ticks to wait before randomising from this trigger and action variable arrays
												self.get_node("FootLeftHelper"),500,quickActionLoadouts["walkNormalLimbs"]
											],
											[ 
												self.get_node("FootRightHelper"),500,quickActionLoadouts["walkNormalLimbs"]
											],
											[ 
												self.get_node("HandRightHelper"),500,quickActionLoadouts["walkNormalLimbs"]
											],
											[ 
												self.get_node("HandLeftHelper"),500,quickActionLoadouts["walkNormalLimbs"]
											],
											[ 
												self.get_node("HandLeft/meshes_default"),500,quickActionLoadouts["meshSwapAttach"]
											]
										],
										[ #random variant 1 of action
											[ 
												self.get_node("FootLeftHelper"),500,quickActionLoadouts["walkStrafeLeftLimbs"]
											],
											[ 
												self.get_node("FootRightHelper"),500,quickActionLoadouts["walkStrafeLeftLimbs"]
											],
											[ 
												self.get_node("HandRightHelper"),500,quickActionLoadouts["walkStrafeLeftLimbs"]
											],
											[ 
												self.get_node("HandLeftHelper"),500,quickActionLoadouts["walkStrafeLeftLimbs"]
											],
											[ 
												self.get_node("HandLeft/meshes_default"),500,quickActionLoadouts["meshSwapAttach"]
											]
										],
										[ #random variant 2 of action
											[ 
												self.get_node("FootLeftHelper"),500,quickActionLoadouts["walkStrafeRightLimbs"]
											],
											[ 
												self.get_node("FootRightHelper"),500,quickActionLoadouts["walkStrafeRightLimbs"]
											],
											[ 
												self.get_node("HandRightHelper"),500,quickActionLoadouts["walkStrafeRightLimbs"]
											],
											[ 
												self.get_node("HandLeftHelper"),500,quickActionLoadouts["walkStrafeRightLimbs"]
											],
											[ 
												self.get_node("HandLeft/meshes_default"),500,quickActionLoadouts["meshSwapAttach"]
											]
										]
									]
								}
							}
							
	#list of actions to use when close to a target
	self.closeResponseActions = {"ANY":
								{3:
									[ #move action for any subtarget at emotion value of 3
										[ #random variant 0 of action
											[ #name for this action, node to update, ticks to wait before randomising from this trigger and action variable arrays
												self.get_node("FootLeftHelper"),500,quickActionLoadouts["standIdleLimbs"]
											],
											[ 
												self.get_node("FootRightHelper"),500,quickActionLoadouts["standIdleLimbs"]
											],
											[ 
												self.get_node("HandRightHelper"),500,quickActionLoadouts["standIdleLimbs"]
											],
											[ 
												self.get_node("HandLeftHelper"),500,quickActionLoadouts["standIdleLimbs"]
											],
											[ 
												self.get_node("HandLeft/meshes_default"),500,quickActionLoadouts["meshSwapAttach"]
											]
										]
									]
								}
							}
							
	#list of actions to use when close to a target
	self.farResponseActions = 	{"ANY":
								{3:
									[ #far action for any subtarget at emotion value of 3
										[ #random variant 0 of action
											[ #name for this action, node to update, ticks to wait before randomising from this trigger and action variable arrays
												self.get_node("FootLeftHelper"),500,quickActionLoadouts["standIdleLimbs"]
											],
											[ 
												self.get_node("FootRightHelper"),500,quickActionLoadouts["standIdleLimbs"]
											],
											[ 
												self.get_node("HandRightHelper"),500,quickActionLoadouts["farWaveArms"]
											],
											[ 
												self.get_node("HandLeftHelper"),500,quickActionLoadouts["farWaveArms"]
											],
											[ 
												self.get_node("HandLeft/meshes_default"),500,quickActionLoadouts["meshSwapWave"]
											]
										]
									]
								}
							}
	


