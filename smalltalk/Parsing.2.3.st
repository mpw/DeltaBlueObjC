!Method methodsFor: 'private'!

parse: methodString
	"Answer the Smalltalk parse tree for the given string."

	^(Compiler new)
		parse: methodString readStream
		in: UndefinedObject
		notifying: nil! !

!ParseNode methodsFor: 'DeltaBlue'!

allVariables
	"Answer a set containing all variables used in this parse tree."

	| vars |
	vars _ IdentitySet new.
	self apply:
		[: node |
		 (node isMemberOf: VariableNode)
			ifTrue: [vars add: node name asSymbol].
		 true].

	self removePredefinedVarsFrom: vars.
	^vars!

assignedTo
	"Answer a collection of the variables assigned to in this parse tree."

	| vars |
	vars _ IdentitySet new.
	self apply:
		[: node |
		 (node isMemberOf: AssignmentNode)
			ifTrue: [vars add: node variable name asSymbol].
		 true].

	self removePredefinedVarsFrom: vars.
	^vars!

referenced
	"Answer a collection of the variables that are referenced but not assigned to in this parse tree."

	| vars |
	vars _ IdentitySet new.
	self apply:
		[: node |
		 (node isMemberOf: VariableNode)
			ifTrue: [vars add: node name asSymbol. true]
			ifFalse:
				[(node isMemberOf: AssignmentNode)
					ifTrue: [vars addAll: node value referenced. false]
					ifFalse: [true]]].

	self removePredefinedVarsFrom: vars.
	^vars!

removePredefinedVarsFrom: varList
	"Remove the pre-defined variable names from the given collection."

	#(self super true false nil thisContext) do:
		[: predefinedVar |
			varList remove: predefinedVar ifAbsent: []].! !

!MethodNode methodsFor: 'DeltaBlue'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[block apply: aBlock].! !

!MessageNode methodsFor: 'DeltaBlue'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[(receiver notNil)
			ifTrue: [receiver apply: aBlock].
		 arguments do: [: a | a apply: aBlock]].! !

!BlockNode methodsFor: 'DeltaBlue'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[statements do: [: s | s apply: aBlock]].! !

!LeafNode methodsFor: 'DeltaBlue'!

apply: aBlock

	aBlock value: self.! !

!CascadeNode methodsFor: 'DeltaBlue'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[receiver apply: aBlock.
		 messages do: [: m | m apply: aBlock]].! !

!VariableNode methodsFor: 'DeltaBlue'!

name

	^name! !

!ReturnNode methodsFor: 'DeltaBlue'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[expr apply: aBlock].! !

!AssignmentNode methodsFor: 'DeltaBlue'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[variable apply: aBlock.
		 value apply: aBlock].!

value

	^value!

variable

	^variable! !
