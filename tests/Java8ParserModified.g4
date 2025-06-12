/*
 * [The "BSD license"]
 *  Copyright (c) 2014 Terence Parr
 *  Copyright (c) 2014 Sam Harwell
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * A Java 8 grammar for ANTLR 4 derived from the Java Language Specification
 * chapter 19.
 *
 * NOTE: This grammar results in a generated parser that is much slower
 *       than the Java 7 grammar in the grammars-v4/java directory. This
 *     one is, however, extremely close to the spec.
 *
 * You can test with
 *
 *  $ antlr4 Java8.g4
 *  $ javac *.java
 *  $ grun Java8 compilationUnit *.java
 *
 * Or,
~/antlr/code/grammars-v4/java8 $ java Test .
/Users/parrt/antlr/code/grammars-v4/java8/./Java8BaseListener.java
/Users/parrt/antlr/code/grammars-v4/java8/./Java8Lexer.java
/Users/parrt/antlr/code/grammars-v4/java8/./Java8Listener.java
/Users/parrt/antlr/code/grammars-v4/java8/./Java8Parser.java
/Users/parrt/antlr/code/grammars-v4/java8/./Test.java
Total lexer+parser time 30844ms.
 */

// $antlr-format alignTrailingComments true, columnLimit 150, minEmptyLines 1, maxEmptyLinesToKeep 1, reflowComments false, useTab false
// $antlr-format allowShortRulesOnASingleLine false, allowShortBlocksOnASingleLine true, alignSemicolons hanging, alignColons hanging

parser grammar Java8ParserModified;

options {
    tokenVocab = Java8Lexer;
}

/*
 * Productions from §3 (Lexical Structure)
 */

literal
    : IntegerLiteral
    | FloatingPointLiteral
    | BooleanLiteral
    | CharacterLiteral
    | StringLiteral
    | NullLiteral
    ;

/*
 * Productions from §4 (Types, Values, and Variables)
 */

primitiveType
    : annotation* numericType
    | annotation* 'boolean'
    ;

numericType
    : integralType
    | floatingPointType
    ;

integralType
    : 'byte'
    | 'short'
    | 'int'
    | 'long'
    | 'char'
    ;

floatingPointType
    : 'float'
    | 'double'
    ;

referenceType
    : classOrInterfaceType
    | typeVariable
    | arrayType
    ;

classOrInterfaceType
    : (classType_lfno_classOrInterfaceType | interfaceType_lfno_classOrInterfaceType) (
        classType_lf_classOrInterfaceType
        | interfaceType_lf_classOrInterfaceType
    )*
    ;

classType
    : annotation* Identifier '<' typeArgument (',' typeArgument)* '>'?
    | classOrInterfaceType '.' annotation* Identifier '<' typeArgument (',' typeArgument)* '>'?
    ;

classType_lf_classOrInterfaceType
    : '.' annotation* Identifier '<' typeArgument (',' typeArgument)* '>'?
    ;

classType_lfno_classOrInterfaceType
    : annotation* Identifier '<' typeArgument (',' typeArgument)* '>'?
    ;

interfaceType_lf_classOrInterfaceType
    : classType_lf_classOrInterfaceType
    ;

interfaceType_lfno_classOrInterfaceType
    : classType_lfno_classOrInterfaceType
    ;

typeVariable
    : annotation* Identifier
    ;

arrayType
    : primitiveType dims
    | classOrInterfaceType dims
    | typeVariable dims
    ;

dims
    : annotation* '[' ']' (annotation* '[' ']')*
    ;

typeParameter
    : annotation* Identifier typeBound?
    ;

typeBound
    : 'extends' typeVariable
    | 'extends' classOrInterfaceType '&' classType*
    ;


typeArgument
    : referenceType
    | annotation* '?' wildcardBounds?
    ;

wildcardBounds
    : 'extends' referenceType
    | 'super' referenceType
    ;

/*
 * Productions from §6 (Names)
 */

packageName
    : Identifier
    | packageName '.' Identifier
    ;

typeName
    : Identifier
    | packageOrTypeName '.' Identifier
    ;

packageOrTypeName
    : Identifier
    | packageOrTypeName '.' Identifier
    ;

expressionName
    : Identifier
    | ambiguousName '.' Identifier
    ;

methodName
    : Identifier
    ;

ambiguousName
    : Identifier
    | ambiguousName '.' Identifier
    ;

/*
 * Productions from §7 (Packages)
 */

compilationUnit
    : packageDeclaration? importDeclaration* typeDeclaration* EOF
    ;

packageDeclaration
    : packageModifier* 'package' packageName ';'
    ;

packageModifier
    : annotation
    ;

importDeclaration
    : singleTypeImportDeclaration
    | typeImportOnDemandDeclaration
    | singleStaticImportDeclaration
    | staticImportOnDemandDeclaration
    ;

singleTypeImportDeclaration
    : 'import' typeName ';'
    ;

typeImportOnDemandDeclaration
    : 'import' packageOrTypeName '.' '*' ';'
    ;

singleStaticImportDeclaration
    : 'import' 'static' typeName '.' Identifier ';'
    ;

staticImportOnDemandDeclaration
    : 'import' 'static' typeName '.' '*' ';'
    ;

typeDeclaration
    : classDeclaration
    | interfaceDeclaration
    | ';'
    ;

/*
 * Productions from §8 (Classes)
 */

classDeclaration
    : normalClassDeclaration
    | enumDeclaration
    ;

normalClassDeclaration
    : classModifier* 'class' Identifier '<' typeParameter (',' typeParameter)* '>'? 'extends' classType? 'implements' classType (',' classType)*? '{' classBodyDeclaration* '}'
    ;

classModifier
    : annotation
    | 'public'
    | 'protected'
    | 'private'
    | 'abstract'
    | 'static'
    | 'final'
    | 'strictfp'
    ;

classBodyDeclaration
    : classMemberDeclaration
    | block
    | 'static' block
    | constructorDeclaration
    ;

classMemberDeclaration
    : fieldDeclaration
    | methodDeclaration
    | classDeclaration
    | interfaceDeclaration
    | ';'
    ;

fieldDeclaration
    : fieldModifier* unannType variableDeclaratorList ';'
    ;

fieldModifier
    : annotation
    | 'public'
    | 'protected'
    | 'private'
    | 'static'
    | 'final'
    | 'transient'
    | 'volatile'
    ;

variableDeclaratorList
    : variableDeclarator (',' variableDeclarator)*
    ;

variableDeclarator
    : variableDeclaratorId ('=' variableInitializer)?
    ;

variableDeclaratorId
    : Identifier dims?
    ;

variableInitializer
    : expression
    | arrayInitializer
    ;

unannType
    : unannPrimitiveType
    | unannReferenceType
    ;

unannPrimitiveType
    : numericType
    | 'boolean'
    ;

unannReferenceType
    : unannClassOrInterfaceType
    | Identifier
    | unannArrayType
    ;

unannClassOrInterfaceType
    : Identifier ('<' typeArgument (',' typeArgument)* '>' | ('.' annotation* Identifier '<' typeArgument (',' typeArgument)* '>'?))* ;


unannArrayType
    : unannPrimitiveType dims
    | unannClassOrInterfaceType dims
    | Identifier dims
    ;

methodDeclaration
    : methodModifier* methodHeader methodBody
    ;

methodModifier
    : annotation
    | 'public'
    | 'protected'
    | 'private'
    | 'abstract'
    | 'static'
    | 'final'
    | 'synchronized'
    | 'native'
    | 'strictfp'
    ;

methodHeader
    : result Identifier '(' formalParameterList? ')' dims? 'throws' exceptionType (',' exceptionType)*?
    | '<' typeParameter (',' typeParameter)* '>' annotation* result Identifier '(' formalParameterList? ')' dims? 'throws' exceptionType (',' exceptionType)*?
    ;

result
    : unannType
    | 'void'
    ;

formalParameterList
    : annotation* unannType (Identifier '.')? 'this'
    | formalParameters ',' lastFormalParameter
    | lastFormalParameter
    ;

formalParameters
    : formalParameter (',' formalParameter)*
    | annotation* unannType (Identifier '.')? 'this' (',' formalParameter)*
    ;

formalParameter
    : variableModifier* unannType variableDeclaratorId
    ;

variableModifier
    : annotation
    | 'final'
    ;

lastFormalParameter
    : variableModifier* unannType annotation* '...' variableDeclaratorId
    | formalParameter
    ;

exceptionType
    : classType
    | typeVariable
    ;

methodBody
    : block
    | ';'
    ;

constructorDeclaration
    : constructorModifier* constructorDeclarator 'throws' exceptionType (',' exceptionType)*? constructorBody
    ;

constructorModifier
    : annotation
    | 'public'
    | 'protected'
    | 'private'
    ;

constructorDeclarator
    : '<' typeParameter (',' typeParameter)* '>'? simpleTypeName '(' formalParameterList? ')'
    ;

simpleTypeName
    : Identifier
    ;

constructorBody
    : '{' explicitConstructorInvocation? blockStatements? '}'
    ;

explicitConstructorInvocation
    : '<' typeArgument (',' typeArgument)* '>'? 'this' '(' expression (',' expression)*? ')' ';'
    | '<' typeArgument (',' typeArgument)* '>'? 'super' '(' expression (',' expression)*? ')' ';'
    | expressionName '.' '<' typeArgument (',' typeArgument)* '>'? 'super' '(' expression (',' expression)*? ')' ';'
    | primary '.' '<' typeArgument (',' typeArgument)* '>'? 'super' '(' expression (',' expression)*? ')' ';'
    ;

enumDeclaration
    : classModifier* 'enum' Identifier 'implements' classType (',' classType)*? enumBody
    ;

enumBody
    : '{' enumConstantList? ','? enumBodyDeclarations? '}'
    ;

enumConstantList
    : enumConstant (',' enumConstant)*
    ;

enumConstant
    : enumConstantModifier* Identifier ('(' expression (',' expression)*? ')')? '{' classBodyDeclaration* '}'?
    ;

enumConstantModifier
    : annotation
    ;

enumBodyDeclarations
    : ';' classBodyDeclaration*
    ;

/*
 * Productions from §9 (Interfaces)
 */

interfaceDeclaration
    : normalInterfaceDeclaration
    | annotationTypeDeclaration
    ;

normalInterfaceDeclaration
    : interfaceModifier* 'interface' Identifier '<' typeParameter (',' typeParameter)* '>'? 'extends' classType (',' classType)*? '{' interfaceMemberDeclaration* '}'
    ;

interfaceModifier
    : annotation
    | 'public'
    | 'protected'
    | 'private'
    | 'abstract'
    | 'static'
    | 'strictfp'
    ;

interfaceMemberDeclaration
    : constantModifier* unannType variableDeclaratorList ';'
    | interfaceMethodDeclaration
    | classDeclaration
    | interfaceDeclaration
    | ';'
    ;

constantModifier
    : annotation
    | 'public'
    | 'static'
    | 'final'
    ;

interfaceMethodDeclaration
    : interfaceMethodModifier* methodHeader methodBody
    ;

interfaceMethodModifier
    : annotation
    | 'public'
    | 'abstract'
    | 'default'
    | 'static'
    | 'strictfp'
    ;

annotationTypeDeclaration
    : interfaceModifier* '@' 'interface' Identifier annotationTypeBody
    ;

annotationTypeBody
    : '{' annotationTypeMemberDeclaration* '}'
    ;

annotationTypeMemberDeclaration
    : annotationTypeElementDeclaration
    | constantModifier* unannType variableDeclaratorList ';'
    | classDeclaration
    | interfaceDeclaration
    | ';'
    ;

annotationTypeElementDeclaration
    : annotationTypeElementModifier* unannType Identifier '(' ')' dims? defaultValue? ';'
    ;

annotationTypeElementModifier
    : annotation
    | 'public'
    | 'abstract'
    ;

defaultValue
    : 'default' elementValue
    ;

annotation
    : normalAnnotation
    | markerAnnotation
    | singleElementAnnotation
    ;

normalAnnotation
    : '@' typeName '(' elementValuePairList? ')'
    ;

elementValuePairList
    : elementValuePair (',' elementValuePair)*
    ;

elementValuePair
    : Identifier '=' elementValue
    ;

elementValue
    : conditionalExpression
    | elementValueArrayInitializer
    | annotation
    ;

elementValueArrayInitializer
    : '{' elementValueList? ','? '}'
    ;

elementValueList
    : elementValue (',' elementValue)*
    ;

markerAnnotation
    : '@' typeName
    ;

singleElementAnnotation
    : '@' typeName '(' elementValue ')'
    ;

/*
 * Productions from §10 (Arrays)
 */

arrayInitializer
    : '{' variableInitializerList? ','? '}'
    ;

variableInitializerList
    : variableInitializer (',' variableInitializer)*
    ;

/*
 * Productions from §14 (Blocks and Statements)
 */

block
    : '{' blockStatements? '}'
    ;

blockStatements
    : blockStatement+
    ;

blockStatement
    : localVariableDeclarationStatement
    | classDeclaration
    | statement
    ;

localVariableDeclarationStatement
    : localVariableDeclaration ';'
    ;

localVariableDeclaration
    : variableModifier* unannType variableDeclaratorList
    ;

statement
    : statementWithoutTrailingSubstatement
    | labeledStatement
    | ifThenStatement
    | ifThenElseStatement
    | 'while' '(' expression ')' statement
    | forStatement
    ;

statementNoShortIf
    : statementWithoutTrailingSubstatement
    | labeledStatementNoShortIf
    | ifThenElseStatementNoShortIf
    | 'while' '(' expression ')' statementNoShortIf
    | forStatementNoShortIf
    ;

statementWithoutTrailingSubstatement
    : block
    | emptyStatement_
    | expressionStatement
    | assertStatement
    | switchStatement
    | doStatement
    | 'break' Identifier? ';'
    | 'continue' Identifier? ';'
    | 'return' expression? ';'
    | 'synchronized' '(' expression ')' block
    | 'throw' expression ';'
    | tryStatement
    ;

emptyStatement_
    : ';'
    ;

labeledStatement
    : Identifier ':' statement
    ;

labeledStatementNoShortIf
    : Identifier ':' statementNoShortIf
    ;

expressionStatement
    : statementExpression ';'
    ;


classCreatorRest
    : 
    ;

statementExpression
    : variableDeclaratorId '=' expression
    | '++' primary
    | '--' primary
    | primary '++'
    | primary '--'
    | expressionName '(' expression (',' expression)*? ')'
    | 'new' '<' typeArgument (',' typeArgument)* '>'? Identifier ('.' Identifier)* classCreatorRest
    ;



ifThenStatement
    : 'if' '(' expression ')' statement
    ;

ifThenElseStatement
    : 'if' '(' expression ')' statementNoShortIf 'else' statement
    ;

ifThenElseStatementNoShortIf
    : 'if' '(' expression ')' statementNoShortIf 'else' statementNoShortIf
    ;

assertStatement
    : 'assert' expression ';'
    | 'assert' expression ':' expression ';'
    ;

switchStatement
    : 'switch' '(' expression ')' switchBlock
    ;

switchBlock
    : '{' switchBlockStatementGroup* switchLabel* '}'
    ;

switchBlockStatementGroup
    : switchLabels blockStatements
    ;

switchLabels
    : switchLabel switchLabel*
    ;

switchLabel
    : 'case' constantExpression ':'
    | 'case' enumConstantName ':'
    | 'default' ':'
    ;

enumConstantName
    : Identifier
    ;

doStatement
    : 'do' statement 'while' '(' expression ')' ';'
    ;

forStatement
    : basicForStatement
    | 'for' '(' variableModifier* unannType variableDeclaratorId ':' expression ')' statement
    ;

forStatementNoShortIf
    : basicForStatementNoShortIf
    | 'for' '(' variableModifier* unannType variableDeclaratorId ':' expression ')' statementNoShortIf
    ;

basicForStatement
    : 'for' '(' forInit? ';' expression? ';' statementExpression (',' statementExpression)*? ')' statement
    ;

basicForStatementNoShortIf
    : 'for' '(' forInit? ';' expression? ';' statementExpression (',' statementExpression)*? ')' statementNoShortIf
    ;

forInit
    : statementExpression (',' statementExpression)*
    | localVariableDeclaration
    ;

tryStatement
    : 'try' block catches
    | 'try' block catches? finally_
    | tryWithResourcesStatement
    ;

catches
    : catchClause catchClause*
    ;

catchClause
    : 'catch' '(' catchFormalParameter ')' block
    ;

catchFormalParameter
    : variableModifier* catchType variableDeclaratorId
    ;

catchType
    : unannClassOrInterfaceType ('|' classType)*
    ;

finally_
    : 'finally' block
    ;

tryWithResourcesStatement
    : 'try' resourceSpecification block catches? finally_?
    ;

resourceSpecification
    : '(' resourceList ';'? ')'
    ;

resourceList
    : resource (';' resource)*
    ;

resource
    : variableModifier* unannType variableDeclaratorId '=' expression
    ;

/*
 * Productions from §15 (Expressions)
 */

primary
    : (primaryNoNewArray_lfno_primary | arrayCreationExpression) primaryNoNewArray_lf_primary*
    ;

primaryNoNewArray
    : literal
    | typeName ('[' ']')* '.' 'class'
    | 'void' '.' 'class'
    | 'this'
    | typeName '.' 'this'
    | '(' expression ')'
    | classInstanceCreationExpression
    | fieldAccess
    | arrayAccess
    | methodInvocation
    | methodReference
    ;

primaryNoNewArray_lf_arrayAccess
    :
    ;

primaryNoNewArray_lfno_arrayAccess
    : literal
    | typeName ('[' ']')* '.' 'class'
    | 'void' '.' 'class'
    | 'this'
    | typeName '.' 'this'
    | '(' expression ')'
    | classInstanceCreationExpression
    | fieldAccess
    | methodInvocation
    | methodReference
    ;

primaryNoNewArray_lf_primary
    : classInstanceCreationExpression_lf_primary
    | '.' Identifier
    | arrayAccess_lf_primary
    | methodInvocation_lf_primary
    | methodReference_lf_primary
    ;

primaryNoNewArray_lf_primary_lf_arrayAccess_lf_primary
    :
    ;

primaryNoNewArray_lf_primary_lfno_arrayAccess_lf_primary
    : classInstanceCreationExpression_lf_primary
    | '.' Identifier
    | methodInvocation_lf_primary
    | methodReference_lf_primary
    ;

primaryNoNewArray_lfno_primary
    : literal
    | typeName ('[' ']')* '.' 'class'
    | unannPrimitiveType ('[' ']')* '.' 'class'
    | 'void' '.' 'class'
    | 'this'
    | typeName '.' 'this'
    | '(' expression ')'
    | classInstanceCreationExpression_lfno_primary
    | fieldAccess_lfno_primary
    | arrayAccess_lfno_primary
    | methodInvocation_lfno_primary
    | methodReference_lfno_primary
    ;

primaryNoNewArray_lfno_primary_lf_arrayAccess_lfno_primary
    :
    ;

primaryNoNewArray_lfno_primary_lfno_arrayAccess_lfno_primary
    : literal
    | typeName ('[' ']')* '.' 'class'
    | unannPrimitiveType ('[' ']')* '.' 'class'
    | 'void' '.' 'class'
    | 'this'
    | typeName '.' 'this'
    | '(' expression ')'
    | classInstanceCreationExpression_lfno_primary
    | fieldAccess_lfno_primary
    | methodInvocation_lfno_primary
    | methodReference_lfno_primary
    ;

classInstanceCreationExpression
    : 'new' '<' typeArgument (',' typeArgument)* '>'? annotation* Identifier ('.' annotation* Identifier)* typeArgumentsOrDiamond? '(' expression (',' expression)*? ')' '{' classBodyDeclaration* '}'?
    | expressionName '.' 'new' '<' typeArgument (',' typeArgument)* '>'? annotation* Identifier typeArgumentsOrDiamond? '(' expression (',' expression)*? ')' '{' classBodyDeclaration* '}'?
    | primary '.' 'new' '<' typeArgument (',' typeArgument)* '>'? annotation* Identifier typeArgumentsOrDiamond? '(' expression (',' expression)*? ')' '{' classBodyDeclaration* '}'?
    ;

classInstanceCreationExpression_lf_primary
    : '.' 'new' '<' typeArgument (',' typeArgument)* '>'? annotation* Identifier typeArgumentsOrDiamond? '(' expression (',' expression)*? ')' '{' classBodyDeclaration* '}'?
    ;

classInstanceCreationExpression_lfno_primary
    : 'new' '<' typeArgument (',' typeArgument)* '>'? annotation* Identifier ('.' annotation* Identifier)* typeArgumentsOrDiamond? '(' expression (',' expression)*? ')' '{' classBodyDeclaration* '}'?
    | expressionName '.' 'new' '<' typeArgument (',' typeArgument)* '>'? annotation* Identifier typeArgumentsOrDiamond? '(' expression (',' expression)*? ')' '{' classBodyDeclaration* '}'?
    ;

typeArgumentsOrDiamond
    : '<' typeArgument (',' typeArgument)* '>'
    | '<' '>'
    ;

fieldAccess
    : primary '.' Identifier
    | 'super' '.' Identifier
    | typeName '.' 'super' '.' Identifier
    ;

fieldAccess_lfno_primary
    : 'super' '.' Identifier
    | typeName '.' 'super' '.' Identifier
    ;

arrayAccess
    : (expressionName '[' expression ']' | primaryNoNewArray_lfno_arrayAccess '[' expression ']') (
        primaryNoNewArray_lf_arrayAccess '[' expression ']'
    )*
    ;

arrayAccess_lf_primary
    : primaryNoNewArray_lf_primary_lfno_arrayAccess_lf_primary '[' expression ']' (
        primaryNoNewArray_lf_primary_lf_arrayAccess_lf_primary '[' expression ']'
    )*
    ;

arrayAccess_lfno_primary
    : (
        expressionName '[' expression ']'
        | primaryNoNewArray_lfno_primary_lfno_arrayAccess_lfno_primary '[' expression ']'
    ) (primaryNoNewArray_lfno_primary_lf_arrayAccess_lfno_primary '[' expression ']')*
    ;

methodInvocation
    : methodName '(' expression (',' expression)*? ')'
    | typeName '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | expressionName '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | primary '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | 'super' '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | typeName '.' 'super' '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    ;

methodInvocation_lf_primary
    : '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    ;

methodInvocation_lfno_primary
    : methodName '(' expression (',' expression)*? ')'
    | typeName '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | expressionName '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | 'super' '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    | typeName '.' 'super' '.' '<' typeArgument (',' typeArgument)* '>'? Identifier '(' expression (',' expression)*? ')'
    ;

methodReference
    : expressionName '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | referenceType '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | primary '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | 'super' '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | typeName '.' 'super' '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | classType '::' '<' typeArgument (',' typeArgument)* '>'? 'new'
    | arrayType '::' 'new'
    ;

methodReference_lf_primary
    : '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    ;

methodReference_lfno_primary
    : expressionName '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | referenceType '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | 'super' '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | typeName '.' 'super' '::' '<' typeArgument (',' typeArgument)* '>'? Identifier
    | classType '::' '<' typeArgument (',' typeArgument)* '>'? 'new'
    | arrayType '::' 'new'
    ;

arrayCreationExpression
    : 'new' primitiveType dimExprs dims?
    | 'new' classOrInterfaceType dimExprs dims?
    | 'new' primitiveType dims arrayInitializer
    | 'new' classOrInterfaceType dims arrayInitializer
    ;

dimExprs
    : dimExpr dimExpr*
    ;

dimExpr
    : annotation* '[' expression ']'
    ;

constantExpression
    : expression
    ;

expression
    : lambdaExpression
    | assignmentExpression
    ;

lambdaExpression
    : lambdaParameters '->' lambdaBody
    ;

lambdaParameters
    : Identifier
    | '(' formalParameterList? ')'
    | '(' inferredFormalParameterList ')'
    ;

inferredFormalParameterList
    : Identifier (',' Identifier)*
    ;

lambdaBody
    : expression
    | block
    ;

assignmentExpression
    : conditionalExpression
    | assignment
    ;

assignment
    : leftHandSide assignmentOperator expression
    ;

leftHandSide
    : expressionName
    | fieldAccess
    | arrayAccess
    ;

assignmentOperator
    : '='
    | '*='
    | '/='
    | '%='
    | '+='
    | '-='
    | '<<='
    | '>>='
    | '>>>='
    | '&='
    | '^='
    | '|='
    ;

conditionalExpression
    : conditionalExpression '?' expression ':' conditionalExpression
    | conditionalExpression '||' conditionalExpression
    | conditionalExpression '&&' conditionalExpression
    | conditionalExpression '|' conditionalExpression
    | conditionalExpression '^' conditionalExpression
    | conditionalExpression '&' conditionalExpression
    | conditionalExpression '==' conditionalExpression
    | conditionalExpression '!=' conditionalExpression
    | conditionalExpression '<' conditionalExpression
    | conditionalExpression '>' conditionalExpression
    | conditionalExpression '<=' conditionalExpression
    | conditionalExpression '>=' conditionalExpression
    | conditionalExpression 'instanceof' referenceType
    | conditionalExpression '<' '<' conditionalExpression
    | conditionalExpression '>' '>' conditionalExpression
    | conditionalExpression '>' '>' '>' conditionalExpression
    | conditionalExpression '+' conditionalExpression
    | conditionalExpression '-' conditionalExpression
    | conditionalExpression '*' conditionalExpression
    | conditionalExpression '/' conditionalExpression
    | conditionalExpression '%' conditionalExpression
    | '++' conditionalExpression
    | '--' conditionalExpression
    | '+' conditionalExpression
    | '-' conditionalExpression
    | '~' conditionalExpression
    | '!' conditionalExpression
    | '(' primitiveType ')' conditionalExpression
    | '(' referenceType ')' conditionalExpression
    | primary
    | expressionName
    | conditionalExpression '++'
    | conditionalExpression '--'
    | conditionalExpression '?' expression ':' conditionalExpression
    ;
