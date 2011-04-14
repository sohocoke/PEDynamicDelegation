//
//  NSObject+PEDynamicDelegation.m
//  PEDynamicDelegation
//
//  Created by ilo-robbie on 14/04/2011.
//  Copyright 2011 TheFunHouseProject. All rights reserved.
//

#import "NSObject+PEDynamicDelegation.h"
#import <objc/runtime.h>
#import "JRSwizzle.h"

/*@
 #import <Foundation/Foundation.h>

*/ 
@implementation NSObject (PEDynamicDelegation)

static NSString* const kMixin = @"kMixin";
static NSString* const kSwizzled = @"kSwizzled";
static NSString* const kMixinClassName = @"kMixinClassName";

+(void)setDynamicDelegateClassName:(NSString*)dynamicDelegateClassName {
	objc_setAssociatedObject(self, kMixinClassName, dynamicDelegateClassName, OBJC_ASSOCIATION_RETAIN);
	
	// swizzle init method to handle transparent initialisation of instances.
	NSError* err = nil;
	[self jr_swizzleMethod:@selector(init) withMethod:@selector(replacement_init) error:&err];
	if (err)
		[NSException raise:@"SwizzleFailure" format:@"failure while swizzling: %@", err];

	// TODO consider throw based on tight spec, or implementation of extended spec
}

-(void)setDynamicDelegate:(id)dynamicDelegate {
	objc_setAssociatedObject(self, kMixin, dynamicDelegate, OBJC_ASSOCIATION_RETAIN);
	
//	 static dispatch_once_t pred;
//	 __block id blockSelf = self;
//	 dispatch_once(&pred, ^{
//	 [[blockSelf class] swizzleMethods];
//	 });
	// swizzling must happen OAOO per class, so the above is insufficient.
	
	id swizzled = objc_getAssociatedObject([self class], kSwizzled);
	if ( ! swizzled) {
		[[self class] swizzleMethods];
		objc_setAssociatedObject([self class], kSwizzled, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
	}
}


#pragma mark -

+(void) swizzleMethods {
	NSError* err = nil;
	[self jr_swizzleMethod:@selector(forwardingTargetForSelector:) withMethod:@selector(replacement_forwardingTargetForSelector:) error:&err];
	if (err)
		[NSException raise:@"SwizzleFailure" format:@"failure while swizzling: %@", err];
	[self jr_swizzleMethod:@selector(respondsToSelector:) withMethod:@selector(replacement_respondsToSelector:) error:&err];
	if (err)
		[NSException raise:@"SwizzleFailure" format:@"failure while swizzling: %@", err];
}


// let the replacement_ prefix indicate a swizzle-candidate method. 
-(id) replacement_init {
	self = [self replacement_init];
	if (self) {
		NSString* delegateClassName = objc_getAssociatedObject([self class], kMixinClassName);
		id mixin = [[[NSClassFromString(delegateClassName) alloc] init] autorelease];
		[self setDynamicDelegate:mixin];
	}
	return self;
}

-(id)replacement_forwardingTargetForSelector:(SEL)selector {
	id delegate = objc_getAssociatedObject(self, kMixin);
	if (delegate)
		return delegate;
	else
		return [self replacement_forwardingTargetForSelector:selector];
}

-(BOOL) replacement_respondsToSelector:(SEL)selector {
	if ([self replacement_respondsToSelector:selector])
		return YES;
	else {
		id delegate = objc_getAssociatedObject(self, kMixin);
		if (delegate)
			return [delegate respondsToSelector:selector];
		else
			return NO;
	}
}

@end
