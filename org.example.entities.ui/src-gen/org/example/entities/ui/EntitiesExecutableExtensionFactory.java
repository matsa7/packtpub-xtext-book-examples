/*
 * generated by Xtext
 */
package org.example.entities.ui;

import org.eclipse.xtext.ui.guice.AbstractGuiceAwareExecutableExtensionFactory;
import org.osgi.framework.Bundle;

import com.google.inject.Injector;

import org.example.entities.ui.internal.EntitiesActivator;

/**
 * This class was generated. Customizations should only happen in a newly
 * introduced subclass. 
 */
public class EntitiesExecutableExtensionFactory extends AbstractGuiceAwareExecutableExtensionFactory {

	@Override
	protected Bundle getBundle() {
		return EntitiesActivator.getInstance().getBundle();
	}
	
	@Override
	protected Injector getInjector() {
		return EntitiesActivator.getInstance().getInjector(EntitiesActivator.ORG_EXAMPLE_ENTITIES_ENTITIES);
	}
	
}