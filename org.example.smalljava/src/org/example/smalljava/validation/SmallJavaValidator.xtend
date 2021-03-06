/*
 * generated by Xtext
 */
package org.example.smalljava.validation

import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.CheckType
import org.example.smalljava.scoping.SmallJavaIndex
import org.example.smalljava.smallJava.SJClass
import org.example.smalljava.smallJava.SJExpression
import org.example.smalljava.smallJava.SJField
import org.example.smalljava.smallJava.SJMember
import org.example.smalljava.smallJava.SJMemberSelection
import org.example.smalljava.smallJava.SJMethod
import org.example.smalljava.smallJava.SJReturn
import org.example.smalljava.smallJava.SJSuper
import org.example.smalljava.smallJava.SJVariableDeclaration
import org.example.smalljava.smallJava.SmallJavaPackage
import org.example.smalljava.typing.SmallJavaTypeConformance
import org.example.smalljava.typing.SmallJavaTypeProvider

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.example.smalljava.util.SmallJavaModelUtil.*

/**
 * Custom validation rules. 
 *
 * see http://www.eclipse.org/Xtext/documentation.html#validation
 */
class SmallJavaValidator extends AbstractSmallJavaValidator {

	@Inject extension SmallJavaIndex
	
	@Inject extension SmallJavaTypeProvider

	@Inject extension SmallJavaTypeConformance
	
	@Inject extension SmallJavaAccessibility
	
	@Inject extension IQualifiedNameProvider
	
	public static val HIERARCHY_CYCLE = "org.example.smalljava.HierarchyCycle";

	public static val DUPLICATE_CLASS = "org.example.smalljava.DuplicateClass"
	
	public static val MEMBER_NOT_ACCESSIBLE = "org.example.smalljava.MemberNotAccessible"
	
	public static val METHOD_INVOCATION_ON_FIELD = "org.example.smalljava.MethodInvocationOnField"
	
	public static val FIELD_SELECTION_ON_METHOD = "org.example.smalljava.FieldSelectionOnMethod"

	public static val INCOMPATIBLE_TYPES = "org.example.smalljava.IncompatibleTypes"

	public static val DUPLICATE_ELEMENT = "org.example.smalljava.DuplicateElement"
	
	public static val UNREACHABLE_CODE = "org.example.smalljava.UnreachableCode"

	public static val MISSING_FINAL_RETURN = "org.example.smalljava.MissingFinalReturn"

	public static val INVALID_ARGS = "org.example.smalljava.InvalidArgs"

	public static val WRONG_METHOD_OVERRIDE = "org.example.smalljava.WrongMethodOverride"
	
	public static val WRONG_SUPER_USAGE = "org.example.smalljava.WrongSuperUsage"

	@Check
	def checkClassHierarchy(SJClass c) {
		if (c.classHierarchy.contains(c)) {
			error("cycle in hierarchy of class '" + c.name + "'",
				SmallJavaPackage::eINSTANCE.SJClass_Superclass,
				HIERARCHY_CYCLE,
				c.superclass.name)
		}
	}

	// perform this check only on file save
	@Check(CheckType::NORMAL)
	def checkDuplicateClassesInFiles(SJClass c) {
		val className = c.fullyQualifiedName
		c.getVisibleClassesDescriptions.forEach[
			desc |
			if (desc.qualifiedName == className && 
					desc.EObjectOrProxy != c && 
					desc.EObjectURI.trimFragment != c.eResource.URI) {
				error(
					"The type " + c.name + " is already defined",
					SmallJavaPackage::eINSTANCE.SJClass_Name,
					DUPLICATE_CLASS
				)
				return
			}
		]
	}
	
	@Check
	def void checkAccessibility(SJMemberSelection sel) {
		val member = sel.member
		if (member != null && !member.isAccessibleFrom(sel) &&
				member.name != null) {
			error(
				'''The «member.access» member «member.name» is not accessible here''',
				SmallJavaPackage::eINSTANCE.SJMemberSelection_Member,
				MEMBER_NOT_ACCESSIBLE
			)
		}
	}

	@Check
	def void checkMemberSelection(SJMemberSelection sel) {
		val member = sel.member
		if (member != null) {
			if (member instanceof SJField && sel.methodinvocation)
				error(
					'''Method invocation on a field''',
					SmallJavaPackage::eINSTANCE.SJMemberSelection_Methodinvocation,
					METHOD_INVOCATION_ON_FIELD
				)
			if (member instanceof SJMethod && !sel.methodinvocation)
				error(
					'''Field selection on a method''',
					SmallJavaPackage::eINSTANCE.SJMemberSelection_Member,
					FIELD_SELECTION_ON_METHOD
				)
		}
	}

	@Check
	def void checkCompatibleTypes(SJExpression exp) {
		val actualType = exp.typeFor
		val expectedType = exp.expectedType
		if (expectedType == null || actualType == null)
			return; // nothing to check
		if (!actualType.isConformant(expectedType)) {
			error("Incompatible types. Expected '" + expectedType?.name
					+ "' but was '" + actualType?.name + "'", null,
					INCOMPATIBLE_TYPES);
		}
	}

	@Check
	def void checkMethodInvocationArguments(SJMemberSelection sel) {
		if (sel.member != null && sel.member instanceof SJMethod) {
			val method = sel.member as SJMethod
			if (method.params.size != sel.args.size) {
				error(
					"Invalid number of arguments. The method " + method.memberAsStringWithType +
					" is not applicable for the arguments " + sel.argsTypesAsStrings,
					SmallJavaPackage::eINSTANCE.SJMemberSelection_Member,
					INVALID_ARGS
				)
			}
		}
	}

	@Check
	def void checkNoDuplicateVariable(SJVariableDeclaration vardecl) {
		val duplicate = vardecl.containingMethod.body.
			getAllContentsOfType(typeof(SJVariableDeclaration)).findFirst[
				it != vardecl && it.name == vardecl.name		
			]
		if (duplicate != null)
			error("Duplicate variable declaration '" + vardecl.name + "'",
				SmallJavaPackage::eINSTANCE.SJSymbol_Name,
				DUPLICATE_ELEMENT
			)
	}

	@Check
	def void checkNoDuplicateMember(SJMember member) {
		val duplicate = member.containingClass.members.findFirst[
			it != member && it.eClass == member.eClass &&
			it.name == member.name
		]
		if (duplicate != null)
			error("Duplicate member '" + member.name + "'",
				SmallJavaPackage::eINSTANCE.SJMember_Name,
				DUPLICATE_ELEMENT
			)
	}

	@Check
	def void checkNoDuplicateClass(SJClass c) {
		if (c.containingProgram.classes.exists[
				it != c && it.name == c.name])
			error("Duplicate class '" + c.name + "'",
				SmallJavaPackage::eINSTANCE.SJClass_Name,
				DUPLICATE_ELEMENT
			)
	}

	@Check
	def void checkNoStatementAfterReturn(SJReturn ret) {
		val statements = ret.containingBlock.statements
		if (statements.last != ret) {
			// put the error on the statement after the return
			error("Unreachable code",
				statements.get(statements.indexOf(ret)+1),
				null, // EStructuralFeature
				UNREACHABLE_CODE
			)
		}
	}

	@Check
	def void checkMethodEndsWithReturn(SJMethod method) {
		if (method.returnStatement == null) {
			error("Method must end with a return statement",
				SmallJavaPackage::eINSTANCE.SJMethod_Body,
				MISSING_FINAL_RETURN
			)
		}
	}

	@Check
	def void checkMethodOverride(SJMethod m) {
		val overridden = m.containingClass.classHierarchy.
			map[methods].flatten.findFirst[it.name==m.name]
		
		if (overridden != null) {
			if (!m.type.isConformant(overridden.type) ||
				!m.params.map[type].elementsEqual(overridden.params.map[type])) {
				error('''The method '«m.name»' must override a superclass method''',
					SmallJavaPackage::eINSTANCE.SJMember_Type,
					WRONG_METHOD_OVERRIDE
				)
			}
		}
	}

	@Check
	def void checkSuper(SJSuper s) {
		if (s.eContainingFeature != SmallJavaPackage::eINSTANCE.SJMemberSelection_Receiver)
			error("'super' can be used only as member selection receiver",
				null, WRONG_SUPER_USAGE)
	}
}
