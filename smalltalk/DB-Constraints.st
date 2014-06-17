AbstractConstraint subclass: #UnaryConstraint
	instanceVariableNames: 'output satisfied '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
UnaryConstraint comment:
'I am an abstract superclass for constraints having a single possible output variable.

Instance variables:
	output		possible output variable <Variable>
	satisfied		true if I am currently satisfied <Boolean>'!


!UnaryConstraint methodsFor: 'initialize-release'!

release

	strength _ nil.
	output _ nil.
	satisfied _ nil.!

var: aVariable strength: strengthSymbol
	"Initialize myself with the given variable and strength."

	strength _ Strength of: strengthSymbol.
	output _ aVariable.
	satisfied _ false.
	self addConstraint.! !

!UnaryConstraint methodsFor: 'queries'!

isSatisfied
	"Answer true if this constraint is satisfied in the current solution."

	^satisfied! !

!UnaryConstraint methodsFor: 'add/remove'!

addToGraph
	"Add myself to the constraint graph."

	output addConstraint: self.
	satisfied _ false.!

removeFromGraph
	"Remove myself from the constraint graph."

	(output == nil) ifFalse: [output removeConstraint: self].
	satisfied _ false.! !

!UnaryConstraint methodsFor: 'planning'!

chooseMethod: mark
	"Decide if I can be satisfied and record that decision."

	satisfied _
		(output mark ~= mark) and:
		[strength stronger: output walkStrength].!

execute
	"Enforce this constraint. Assume that it is satisfied."

	self subclassResponsibility!

inputsDo: aBlock
	"I have no input variables."!

markUnsatisfied
	"Record the fact that I am unsatisfied."

	satisfied _ false.!

output
	"Answer my current output variable."

	^output!

recalculate
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."

	output walkStrength: strength.
	output stay: (self isInput not).
	(output stay) ifTrue: [self execute].	"stay optimization"! !

AbstractConstraint subclass: #BinaryConstraint
	instanceVariableNames: 'v1 v2 direction '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
BinaryConstraint comment:
'I am an abstract superclass for constraints having two possible output variables.

Instance variables:
	v1, v2		possible output variables <Variable>
	direction		one of:
					#forward (v2 is output)
					#backward (	v1 is output)
					nil (not satisfied)'!


!BinaryConstraint methodsFor: 'initialize-release'!

release

	strength _ nil.
	v1 _ nil.
	v2 _ nil.
	direction _ nil.!

var: variable1 var: variable2 strength: strengthSymbol
	"Initialize myself with the given variables and strength."

	strength _ Strength of: strengthSymbol.
	v1 _ variable1.
	v2 _ variable2.
	direction _ nil.
	self addConstraint.! !

!BinaryConstraint methodsFor: 'queries'!

isSatisfied
	"Answer true if this constraint is satisfied in the current solution."

	^direction notNil! !

!BinaryConstraint methodsFor: 'add/remove'!

addToGraph
	"Add myself to the constraint graph."

	v1 addConstraint: self.
	v2 addConstraint: self.
	direction _ nil.!

removeFromGraph
	"Remove myself from the constraint graph."

	(v1 == nil) ifFalse: [v1 removeConstraint: self].
	(v2 == nil) ifFalse: [v2 removeConstraint: self].
	direction _ nil.! !

!BinaryConstraint methodsFor: 'planning'!

chooseMethod: mark
	"Decide if I can be satisfied and which way I should flow based on the relative strength of the variables I relate, and record that decision."

	(v1 mark == mark) ifTrue:		"forward or nothing"
		[((v2 mark ~= mark) and: [strength stronger: v2 walkStrength])
			ifTrue: [^direction _ #forward]
			ifFalse: [^direction _ nil]].

	(v2 mark == mark) ifTrue:		"backward or nothing"
		[((v1 mark ~= mark) and: [strength stronger: v1 walkStrength])
			ifTrue: [^direction _ #backward]
			ifFalse: [^direction _ nil]].

	"if we get here, neither variable is marked, so we have choice"
	(v1 walkStrength weaker: v2 walkStrength)
		ifTrue:
			[(strength stronger: v1 walkStrength)
				ifTrue: [^direction _ #backward]
				ifFalse: [^direction _ nil]]
		ifFalse:
			[(strength stronger: v2 walkStrength)
				ifTrue: [^direction _ #forward]
				ifFalse: [^direction _ nil]].!

execute
	"Enforce this constraint. Assume that it is satisfied."

	self subclassResponsibility!

inputsDo: aBlock
	"Evaluate the given block on my current input variable."

	(direction == #forward)
		ifTrue: [aBlock value: v1]
		ifFalse: [aBlock value: v2].!

markUnsatisfied
	"Record the fact that I am unsatisfied."

	direction _ nil.!

output
	"Answer my current output variable."

	(direction == #forward)
		ifTrue: [^v2]
		ifFalse: [^v1]!

recalculate
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."

	| in out |
	(direction == #forward)
		ifTrue: [in _ v1. out _ v2]
		ifFalse: [in _ v2. out _ v1].
	out walkStrength: (strength weakest: in walkStrength).
	out stay: (in stay).
	(out stay) ifTrue: [self execute].		"stay optimization"! !

BinaryConstraint subclass: #ScaleConstraint
	instanceVariableNames: 'scale offset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
ScaleConstraint comment:
'I relate two variables by the linear scaling relationship: "v2 = (v1 * scale) + offset". Either v1 or v2 may be changed to maintain this relationship but the scale factor and offset are considered read-only.

Instance variables:
	scale		scale factor input variable <Variable>
	offset		offset input variable <Variable>'!


!ScaleConstraint methodsFor: 'initialize-release'!

release

	super release.
	scale _ nil.
	offset _ nil.!

src: srcVar scale: scaleVar offset: offsetVar dst: dstVar strength: strengthSymbol
	"Initialize myself with the given variables and strength."

	strength _ Strength of: strengthSymbol.
	v1 _ srcVar.
	v2 _ dstVar.
	scale _ scaleVar.
	offset _ offsetVar.
	direction _ nil.
	self addConstraint.! !

!ScaleConstraint methodsFor: 'add/remove'!

addToGraph
	"Add myself to the constraint graph."

	v1 addConstraint: self.
	v2 addConstraint: self.
	scale addConstraint: self.
	offset addConstraint: self.
	direction _ nil.!

removeFromGraph
	"Remove myself from the constraint graph."

	(v1 == nil) ifFalse: [v1 removeConstraint: self].
	(v2 == nil) ifFalse: [v2 removeConstraint: self].
	(scale == nil) ifFalse: [scale removeConstraint: self].
	(offset == nil) ifFalse: [offset removeConstraint: self].
	direction _ nil.! !

!ScaleConstraint methodsFor: 'planning'!

execute
	"Enforce this constraint. Assume that it is satisfied."

	(direction == #forward)
		ifTrue: [v2 value: (v1 value * scale value) + offset value]
		ifFalse: [v1 value: (v2 value - offset value) // scale value].!

inputsDo: aBlock
	"Evaluate the given block on my current input variable."

	(direction == #forward)
		ifTrue: [aBlock value: v1; value: scale; value: offset]
		ifFalse: [aBlock value: v2; value: scale; value: offset].!

recalculate
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."

	| in out |
	(direction == #forward)
		ifTrue: [in _ v1. out _ v2]
		ifFalse: [out _ v1. in _ v2].
	out walkStrength: (strength weakest: in walkStrength).
	out stay: ((in stay) and: [(scale stay) and: [offset stay]]).
	(out stay) ifTrue: [self execute].		"stay optimization"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScaleConstraint class
	instanceVariableNames: ''!


!ScaleConstraint class methodsFor: 'instance creation'!

var: src var: scale var: offset var: dst strength: strengthSymbol
	"Install a scale constraint with the given strength on the given variables."

	^(self new) src: src scale: scale offset: offset dst: dst strength: strengthSymbol! !

UnaryConstraint subclass: #XMouseConstraint
	instanceVariableNames: 'xOffset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
XMouseConstraint comment:
'I am a unary input constraint that constrains a variable to the current x-coordinate of the mouse. I contain an offset to normalize the coordinate system to one convenient for the target variable.

Instance variables:
	xOffset		constant x-offset <Number>'!


!XMouseConstraint methodsFor: 'initialize-release'!

var: aVariable offset: aNumber strength: strengthSymbol
	"Install myself with the given variable, x-offset, and strength."

	xOffset _ aNumber.
	self var: aVariable strength: strengthSymbol.! !

!XMouseConstraint methodsFor: 'queries'!

isInput
	"I depend on the state of the mouse."

	^true! !

!XMouseConstraint methodsFor: 'execution'!

execute
	"Enforce this constraint. Assume that it is satisfied."

	output value: (Sensor mousePoint x + xOffset).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XMouseConstraint class
	instanceVariableNames: ''!


!XMouseConstraint class methodsFor: 'instance creation'!

var: aVariable offset: xOffset strength: strengthSymbol
	"Install an XMouse constraint on the given variable with the given offset constant to be added to the raw mouse position."

	^(self new) var: aVariable offset: xOffset strength: strengthSymbol! !

UnaryConstraint subclass: #YMouseConstraint
	instanceVariableNames: 'yOffset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
YMouseConstraint comment:
'I am a unary input constraint that constrains a variable to the current y-coordinate of the mouse. I contain an offset to normalize the coordinate system to one convenient for the target variable.

Instance variables:
	yOffset		constant y-offset <Number>'!


!YMouseConstraint methodsFor: 'initialize-release'!

var: aVariable offset: aNumber strength: strengthSymbol
	"Install myself with the given variable, y-offset, and strength."

	yOffset _ aNumber.
	self var: aVariable strength: strengthSymbol.! !

!YMouseConstraint methodsFor: 'queries'!

isInput
	"I depend on the state of the mouse."

	^true! !

!YMouseConstraint methodsFor: 'execution'!

execute
	"Enforce this constraint. Assume that it is satisfied."

	output value: (Sensor mousePoint y + yOffset).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

YMouseConstraint class
	instanceVariableNames: ''!


!YMouseConstraint class methodsFor: 'instance creation'!

var: aVariable offset: yOffset strength: strengthSymbol
	"Install a YMouse constraint on the given variable with the given offset constant to be added to the raw mouse position."

	^(self new) var: aVariable offset: yOffset strength: strengthSymbol! !

UnaryConstraint subclass: #StayConstraint
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
StayConstraint comment:
'I mark variables that should, with some level of preference, stay the same. I have one method with zero inputs and one output, which does nothing. Planners may exploit the fact that, if I am satisfied, my output will not change during plan execution. This is called "stay optimization."'!


!StayConstraint methodsFor: 'queries'!

includeInPlan
	"Stay constraints have no effect other than to control the planning process."

	^false! !

!StayConstraint methodsFor: 'execution'!

execute
	"Stay constraints do nothing."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StayConstraint class
	instanceVariableNames: ''!


!StayConstraint class methodsFor: 'instance creation'!

var: aVariable strength: strengthSymbol
	"Install a stay constraint with the given strength on the given variable."

	^(self new) var: aVariable strength: strengthSymbol! !

UnaryConstraint subclass: #EditConstraint
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
EditConstraint comment:
'I am a unary input constraint used to mark a variable that the client wishes to change.'!


!EditConstraint methodsFor: 'queries'!

includeInPlan
	"Edit constraints have no effect other than to control the planning process."

	^false!

isInput
	"I indicate that a variable is to be changed by imperative code."

	^true! !

!EditConstraint methodsFor: 'execution'!

execute
	"Edit constraints do nothing."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EditConstraint class
	instanceVariableNames: ''!


!EditConstraint class methodsFor: 'instance creation'!

var: aVariable strength: strengthSymbol
	"Install an edit constraint with the given strength on the given variable."

	^(self new) var: aVariable strength: strengthSymbol! !

BinaryConstraint subclass: #EqualityConstraint
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'DB-Constraints'!
EqualityConstraint comment:
'I constrain two variables to have the same value: "v1 = v2".'!


!EqualityConstraint methodsFor: 'execution'!

execute
	"Enforce this constraint. Assume that it is satisfied."

	(direction == #forward)
		ifTrue: [v2 value: v1 value]
		ifFalse: [v1 value: v2 value].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EqualityConstraint class
	instanceVariableNames: ''!


!EqualityConstraint class methodsFor: 'instance creation'!

var: variable1 var: variable2 strength: strengthSymbol
	"Install a constraint with the given strength equating the given variables."

	^(self new) var: variable1 var: variable2 strength: strengthSymbol! !