grammar JavaParser;
options {tokenVocab = JavaLexer;}




 compilationUnit :
  packageDeclaration? (importDeclaration)* (typeDeclaration)* EOF
  | moduleDeclaration EOF;

 packageDeclaration :
  annotation* PACKAGE qualifiedName ;;

 importDeclaration :
  IMPORT STATIC? qualifiedName (. *)? ;;

 typeDeclaration :
  classOrInterfaceModifier* (classDeclaration);

 modifier :
  classOrInterfaceModifier
  | NATIVE
  | SYNCHRONIZED
  | TRANSIENT
  | VOLATILE;

 classOrInterfaceModifier :
  annotation
  | PUBLIC
  | PROTECTED
  | PRIVATE
  | STATIC
  | ABSTRACT
  | FINAL
  | STRICTFP
  | SEALED
  | NON_SEALED;

 variableModifier :
  FINAL
  | annotation;

 classDeclaration :
  CLASS identifier typeParameters? (EXTENDS typeType)? (IMPLEMENTS typeList)? (PERMITS typeList)? classBody;

 typeParameters :
  < typeParameter (, typeParameter)* >;

 typeParameter :
  annotation* identifier (EXTENDS annotation* typeBound)?;

 typeBound :
  typeType (& typeType)*;

 enumDeclaration :
  ENUM identifier (IMPLEMENTS typeList)? { enumConstants? ,? enumBodyDeclarations? };

 enumConstants :
  enumConstant (, enumConstant)*;

 enumConstant :
  annotation* identifier arguments? classBody?;

 enumBodyDeclarations :
  ; classBodyDeclaration*;

 interfaceDeclaration :
  INTERFACE identifier typeParameters? (EXTENDS typeList)? (PERMITS typeList)? interfaceBody;

 classBody :
  { classBodyDeclaration* };

 interfaceBody :
  { interfaceBodyDeclaration* };

 classBodyDeclaration :
  ;
  | STATIC? block
  | modifier* memberDeclaration;

 memberDeclaration :
  recordDeclaration
  | methodDeclaration
  | genericMethodDeclaration
  | fieldDeclaration
  | constructorDeclaration
  | genericConstructorDeclaration
  | interfaceDeclaration
  | annotationTypeDeclaration
  | classDeclaration
  | enumDeclaration;

 methodDeclaration :
  typeTypeOrVoid identifier formalParameters ([ ])* (THROWS qualifiedNameList)? methodBody;

 methodBody :
  block
  | ;;

 typeTypeOrVoid :
  typeType
  | VOID;

 genericMethodDeclaration :
  typeParameters methodDeclaration;

 genericConstructorDeclaration :
  typeParameters constructorDeclaration;

 constructorDeclaration :
  identifier formalParameters (THROWS qualifiedNameList)? constructorBody:block;

 compactConstructorDeclaration :
  modifier* identifier constructorBody:block;

 fieldDeclaration :
  typeType variableDeclarators ;;

 interfaceBodyDeclaration :
  modifier* interfaceMemberDeclaration
  | ;;

 interfaceMemberDeclaration :
  recordDeclaration
  | constDeclaration
  | interfaceMethodDeclaration
  | genericInterfaceMethodDeclaration
  | interfaceDeclaration
  | annotationTypeDeclaration
  | classDeclaration
  | enumDeclaration;

 constDeclaration :
  typeType constantDeclarator (, constantDeclarator)* ;;

 constantDeclarator :
  identifier ([ ])* = variableInitializer;

 interfaceMethodDeclaration :
  interfaceMethodModifier* interfaceCommonBodyDeclaration;

 interfaceMethodModifier :
  annotation
  | PUBLIC
  | ABSTRACT
  | DEFAULT
  | STATIC
  | STRICTFP;

 genericInterfaceMethodDeclaration :
  interfaceMethodModifier* typeParameters interfaceCommonBodyDeclaration;

 interfaceCommonBodyDeclaration :
  annotation* typeTypeOrVoid identifier formalParameters ([ ])* (THROWS qualifiedNameList)? methodBody;

 variableDeclarators :
  variableDeclarator (, variableDeclarator)*;

 variableDeclarator :
  variableDeclaratorId (= variableInitializer)?;

 variableDeclaratorId :
  identifier ([ ])*;

 variableInitializer :
  arrayInitializer
  | expression;

 arrayInitializer :
  { (variableInitializer (, variableInitializer)* ,?)? };

 classOrInterfaceType :
  (identifier typeArguments? .)* typeIdentifier typeArguments?;

 typeArgument :
  typeType
  | annotation* ? ((EXTENDS) typeType)?;

 qualifiedNameList :
  qualifiedName (, qualifiedName)*;

 formalParameters :
  ( (receiverParameter?) );

 receiverParameter :
  typeType (identifier .)* THIS;

 formalParameterList :
  formalParameter (, formalParameter)* (, lastFormalParameter)?
  | lastFormalParameter;

 formalParameter :
  variableModifier* typeType variableDeclaratorId;

 lastFormalParameter :
  variableModifier* typeType annotation* ... variableDeclaratorId;

 lambdaLVTIList :
  lambdaLVTIParameter (, lambdaLVTIParameter)*;

 lambdaLVTIParameter :
  variableModifier* VAR identifier;

 qualifiedName :
  identifier (. identifier)*;

 literal :
  integerLiteral
  | floatLiteral
  | CHAR_LITERAL
  | STRING_LITERAL
  | BOOL_LITERAL
  | NULL_LITERAL
  | TEXT_BLOCK;

 integerLiteral :
  DECIMAL_LITERAL
  | HEX_LITERAL
  | OCT_LITERAL
  | BINARY_LITERAL;

 floatLiteral :
  FLOAT_LITERAL
  | HEX_FLOAT_LITERAL;

 altAnnotationQualifiedName :
  (identifier DOT)* @ identifier;

 annotation :
  (@ qualifiedName) (( (elementValuePairs)? ))?;

 elementValuePairs :
  elementValuePair (, elementValuePair)*;

 elementValuePair :
  identifier = elementValue;

 elementValue :
  expression
  | annotation
  | elementValueArrayInitializer;

 elementValueArrayInitializer :
  { (elementValue (, elementValue)*)? ,? };

 annotationTypeDeclaration :
  @ INTERFACE identifier annotationTypeBody;

 annotationTypeBody :
  { annotationTypeElementDeclaration* };

 annotationTypeElementDeclaration :
  modifier* annotationTypeElementRest
  | ;;

 annotationTypeElementRest :
  typeType annotationMethodOrConstantRest ;
  | classDeclaration ;?
  | interfaceDeclaration ;?
  | enumDeclaration ;?
  | annotationTypeDeclaration ;?
  | recordDeclaration ;?;

 annotationMethodOrConstantRest :
  annotationMethodRest
  | annotationConstantRest;

 annotationMethodRest :
  identifier ( ) defaultValue?;

 annotationConstantRest :
  variableDeclarators;

 defaultValue :
  DEFAULT elementValue;

 moduleDeclaration :
  OPEN? MODULE qualifiedName moduleBody;

 moduleBody :
  { moduleDirective* };

 moduleDirective :
  REQUIRES requiresModifier* qualifiedName ;
  | EXPORTS qualifiedName (TO qualifiedName)? ;
  | OPENS qualifiedName (TO qualifiedName)? ;
  | USES qualifiedName ;
  | PROVIDES qualifiedName WITH qualifiedName ;;

 requiresModifier :
  TRANSITIVE
  | STATIC;

 recordDeclaration :
  RECORD identifier typeParameters? recordHeader (IMPLEMENTS typeList)? recordBody;

 recordHeader :
  ( recordComponentList? );

 recordComponentList :
  recordComponent (, recordComponent)*;

 recordComponent :
  typeType identifier;

 recordBody :
  { (classBodyDeclaration)* };

 block :
  { blockStatement* };

 blockStatement :
  localVariableDeclaration ;
  | localTypeDeclaration
  | statement;

 localVariableDeclaration :
  variableModifier* (VAR identifier = expression);

 identifier :
  IDENTIFIER
  | MODULE
  | OPEN
  | REQUIRES
  | EXPORTS
  | OPENS
  | TO
  | USES
  | PROVIDES
  | WITH
  | TRANSITIVE
  | YIELD
  | SEALED
  | PERMITS
  | RECORD
  | VAR;

 typeIdentifier :
  IDENTIFIER
  | MODULE
  | OPEN
  | REQUIRES
  | EXPORTS
  | OPENS
  | TO
  | USES
  | PROVIDES
  | WITH
  | TRANSITIVE
  | SEALED
  | PERMITS
  | RECORD;

 localTypeDeclaration :
  classOrInterfaceModifier* (classDeclaration);

 statement :
  blockLabel:block
  | ASSERT expression (: expression)? ;
  | IF parExpression statement (ELSE statement)?
  | FOR ( forControl ) statement
  | WHILE parExpression statement
  | DO statement WHILE parExpression ;
  | TRY block (catchClause+ finallyBlock?)
  | TRY resourceSpecification block catchClause* finallyBlock?
  | SWITCH parExpression { switchBlockStatementGroup* switchLabel* }
  | SYNCHRONIZED parExpression block
  | RETURN expression? ;
  | THROW expression ;
  | BREAK identifier? ;
  | CONTINUE identifier? ;
  | YIELD expression ;
  | SEMI
  | statementExpression:expression ;
  | switchExpression ;?
  | identifierLabel:identifier : statement;

 catchClause :
  CATCH ( variableModifier* catchType identifier ) block;

 catchType :
  qualifiedName (| qualifiedName)*;

 finallyBlock :
  FINALLY block;

 resourceSpecification :
  ( resources ;? );

 resources :
  resource (; resource)*;

 resource :
  variableModifier* (classOrInterfaceType variableDeclaratorId) = expression
  | qualifiedName;

 switchBlockStatementGroup :
  switchLabel+ blockStatement+;

 switchLabel :
  CASE (constantExpression:expression) :
  | DEFAULT :;

 forControl :
  enhancedForControl
  | forInit? ; expression? ; forUpdate:expressionList?;

 forInit :
  localVariableDeclaration
  | expressionList;

 enhancedForControl :
  variableModifier* (typeType) variableDeclaratorId : expression;

 parExpression :
  ( expression );

 expressionList :
  expression (, expression)*;

 methodCall :
  (identifier) arguments;

 expression :
  primary
  | expression [ expression ]
  | expression bop:. (identifier)
  | methodCall
  | expression :: typeArguments? identifier
  | typeType :: (typeArguments? identifier)
  | classType :: typeArguments? NEW
  | switchExpression
  | expression postfix:(++)
  | prefix:(+) expression
  | ( annotation* typeType (& typeType)* ) expression
  | NEW creator
  | expression bop:(*) expression
  | expression bop:(+) expression
  | expression (< <) expression
  | expression bop:(<=) expression
  | expression bop:INSTANCEOF (typeType)
  | expression bop:(==) expression
  | expression bop:& expression
  | expression bop:^ expression
  | expression bop:| expression
  | expression bop:&& expression
  | expression bop:|| expression
  | expression bop:? expression : expression
  | expression bop:(=) expression
  | lambdaExpression;

 pattern :
  variableModifier* typeType annotation* identifier;

 lambdaExpression :
  lambdaParameters -> lambdaBody;

 lambdaParameters :
  identifier
  | ( formalParameterList? )
  | ( identifier (, identifier)* )
  | ( lambdaLVTIList? );

 lambdaBody :
  expression
  | block;

 primary :
  ( expression )
  | THIS
  | SUPER
  | literal
  | identifier
  | typeTypeOrVoid . CLASS
  | nonWildcardTypeArguments (explicitGenericInvocationSuffix);

 switchExpression :
  SWITCH parExpression { switchLabeledRule* };

 switchLabeledRule :
  CASE (expressionList) (ARROW) switchRuleOutcome
  | DEFAULT (ARROW) switchRuleOutcome;

 guardedPattern :
  ( guardedPattern )
  | variableModifier* typeType annotation* identifier (&& expression)*
  | guardedPattern && expression;

 switchRuleOutcome :
  block
  | blockStatement*;

 classType :
  (classOrInterfaceType .)? annotation* identifier typeArguments?;

 creator :
  nonWildcardTypeArguments? createdName classCreatorRest
  | createdName arrayCreatorRest;

 createdName :
  identifier typeArgumentsOrDiamond? (. identifier typeArgumentsOrDiamond?)*
  | primitiveType;

 innerCreator :
  identifier nonWildcardTypeArgumentsOrDiamond? classCreatorRest;

 arrayCreatorRest :
  ([ ])+ arrayInitializer
  | ([ expression ])+ ([ ])*;

 classCreatorRest :
  arguments classBody?;

 explicitGenericInvocation :
  nonWildcardTypeArguments explicitGenericInvocationSuffix;

 typeArgumentsOrDiamond :
  < >
  | typeArguments;

 nonWildcardTypeArgumentsOrDiamond :
  < >
  | nonWildcardTypeArguments;

 nonWildcardTypeArguments :
  < typeList >;

 typeList :
  typeType (, typeType)*;

 typeType :
  annotation* (classOrInterfaceType) (annotation* [ ])*;

 primitiveType :
  BOOLEAN
  | CHAR
  | BYTE
  | SHORT
  | INT
  | LONG
  | FLOAT
  | DOUBLE;

 typeArguments :
  < typeArgument (, typeArgument)* >;

 superSuffix :
  arguments
  | . typeArguments? identifier arguments?;

 explicitGenericInvocationSuffix :
  SUPER superSuffix
  | identifier arguments;

 arguments :
  ( expressionList? );
