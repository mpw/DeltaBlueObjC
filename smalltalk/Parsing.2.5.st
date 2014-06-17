!Method methodsFor: 'private'!

parse: methodString
	"Answer the Smalltalk parse tree for the given string."

	^SmalltalkCompiler
		parse: methodString
		class: UndefinedObject! !

!AssignmentNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[variable apply: aBlock.
		 value apply: aBlock].! !

!BlockNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[arguments do:
			[: arg | arg apply: aBlock].
		 body apply: aBlock].! !

!CascadeNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[receiver apply: aBlock.
		 messages do:
			[: message | message apply: aBlock]].! !

!LiteralNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	aBlock value: self.! !

!MessageNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[receiver apply: aBlock.
		 arguments do: [: arg | arg apply: aBlock]].!

receiver: newReceiver

	receiver _ newReceiver.! !

!MethodNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[block apply: aBlock].! !

!ParameterNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[variable apply: aBlock].! !

!ProgramNode methodsFor: 'ThingLabII'!

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

apply: aBlock
	"Invoke the given block on all nodes of the parse tree whose root is me. The block takes one argument, some kind of ProgramNode, and returns a boolean to indicate whether further exploration of the parse tree is desired. If the value returned by the block is false, then the children of the current node are not visited."

	self subclassResponsibility!

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
					ifFalse:
						[(node isMemberOf: ParameterNode)
							ifTrue: [false]
							ifFalse: [true]]]].

	self removePredefinedVarsFrom: vars.
	^vars!

removePredefinedVarsFrom: varList
	"Remove the pre-defined variable names from the given collection."

	#(self super true false nil thisContext) do:
		[: predefinedVar |
			varList remove: predefinedVar ifAbsent: []].! !

!ReturnNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[value apply: aBlock].! !

!SequenceNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	(aBlock value: self) ifTrue:
		[temporaries do:
			[: temporary | temporary apply: aBlock].
		 statements do:
			[: statement | statement apply: aBlock]].! !

!VariableNode methodsFor: 'ThingLabII'!

apply: aBlock
	"See ProgramNode>apply:"

	aBlock value: self.! !
