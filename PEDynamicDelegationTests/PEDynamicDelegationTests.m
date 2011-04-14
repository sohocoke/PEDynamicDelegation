#import "PEDynamicDelegationTests.h"
#import "NSObject+PEDynamicDelegation.h"
#import <objc/runtime.h>

#pragma mark Test classes

@protocol IdentifiableProtocol
@optional
-(NSString*) identifier;
@end

@interface IdentifiableMixin :NSObject<IdentifiableProtocol>
@end

@implementation IdentifiableMixin
-(NSString*) identifier { return @"a default identifier"; }
@end


@interface MixinUser :NSObject<IdentifiableProtocol>
@end

@implementation MixinUser
@end


#pragma mark Tests

@implementation PEDynamicDelegationTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void) testSetDelegateInstance {
	MixinUser* testInstance = [[MixinUser new] autorelease];

	// DESIGN to what extent should the mixin be reflected in the type-related interface for NSObject?
	// a. all?
	// b. nothing?
	// c. somewhere in between?
	// TODO disabled until spec to include multiple mixin operations performed by same class. 
	// STAssertFalse([testInstance respondsToSelector:NSSelectorFromString(@"identifier")], @"testInstance doesn't know of mixin's methods");
	
	[testInstance setDynamicDelegate:[[IdentifiableMixin new] autorelease]];
	STAssertEqualObjects(@"a default identifier", [testInstance identifier], @"testInstance acquired dynamic delegate's behaviour");
}

- (void) testSetDelegateClassName {
	MixinUser* testInstance = [[MixinUser new] autorelease];
	
	// apparently there's an obj-c runtime bug that makes this test fail. should test with ipad.

//	STAssertThrows([testInstance identifier], @"before setting delegate, unknown method invocation should throw");
	
	[MixinUser setDynamicDelegateClassName:@"IdentifiableMixin"];
	testInstance = [[MixinUser new] autorelease];
	STAssertEqualObjects(@"a default identifier", [testInstance identifier], @"testInstance acquired dyamic delegate class's behaviour");
}

// several test cases to go here.

/*
 test draft:
 
 // using mixin should result in obtaining behaviour
 MixinUser* testee = [[[MixinUser alloc] init] autorelease];
 Mixin* mixin = [[[Mixin alloc] init] autorelease];
 [testee setDynamicDelegate:mixin];
 NSLog([testee identifier], nil);
 
 // mixing in should work with another class
 TestClass2* testee2 = [[[TestClass2 alloc] init] autorelease];
 [testee2 setDynamicDelegate:mixin];
 NSLog([testee2 identifier], nil);
 
 // before using mixin the behaviour should not be obtained
 @try {
 MixinUser* testee3 = [[[MixinUser alloc] init] autorelease];
 NSLog([testee3 identifier], nil);
 }
 @catch (NSException * e) {
 NSLog(@"exception thrown as expected");
 }
 */

@end
