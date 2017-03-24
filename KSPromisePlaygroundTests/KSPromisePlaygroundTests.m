//
//  KSPromisePlaygroundTests.m
//  KSPromisePlaygroundTests
//
//  Created by Lottis, Kent on 3/24/17.
//  Copyright © 2017 Lottis, Kent. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSDeferred.h"

@protocol PromiseMonster
-(KSPromise *) promiseForMonster;
-(void) pokeMonster: (NSString *) monster;
@end

@interface CoolMonster: NSObject<PromiseMonster>
@property (nonatomic, strong) KSDeferred *currentDeferred;
@property (nonatomic, strong) KSDeferred *dependentDefer;
@end

@interface BrokenMonster: NSObject<PromiseMonster>
@property (nonatomic, strong) NSMutableArray<KSDeferred *> *currentDeferreds;
@property (nonatomic, strong) KSDeferred *dependentDefer;
@end

@implementation BrokenMonster
-(instancetype) init {
    self = [super init];
    if (self) {
        _currentDeferreds = [NSMutableArray array];
        _dependentDefer = [KSDeferred defer];
    }
    return self;
}

-(KSPromise *) promiseForMonster {
    KSDeferred *defer = [KSDeferred defer];

    [self.currentDeferreds addObject:defer];
    if (self.currentDeferreds.count > 1) {
        [self.dependentDefer.promise then:^id (NSString * value) {
            NSLog(@"Monster resolving: k: %lu", self.currentDeferreds.count);
            for (KSDeferred *defer in self.currentDeferreds) {
                [defer resolveWithValue:value];
            }
            NSLog(@"Monster resolved: k: %lu", self.currentDeferreds.count);
            [self.currentDeferreds removeAllObjects];
            NSLog(@"Monster cleared: k: %lu", self.currentDeferreds.count);
            return nil;
        }];
    }

    return defer.promise;
}

-(void) pokeMonster: (NSString *) monster {
    [self.dependentDefer resolveWithValue:monster];
}

@end

@implementation CoolMonster
-(instancetype) init {
    self = [super init];
    if (self) {
        _dependentDefer = [KSDeferred defer];
    }
    return self;
}

-(KSPromise *) promiseForMonster {
    if (self.currentDeferred) {
        return self.currentDeferred.promise;
    }

    KSDeferred *defer = [KSDeferred defer];
    self.currentDeferred = defer;
        [self.dependentDefer.promise then:^id (NSString * value) {
            NSLog(@"Cool-monste then");
            [self.currentDeferred resolveWithValue:value];
            self.currentDeferred = nil;
            NSLog(@"Cool-monster cleared");
            return nil;
        }];

    return defer.promise;
}

-(void) pokeMonster: (NSString *) monster {
    [self.dependentDefer resolveWithValue:monster];
}

@end

@interface KSPromisePlaygroundTests : XCTestCase
@end

@implementation KSPromisePlaygroundTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    KSDeferred *target = [KSDeferred defer];
    [target resolveWithValue:@"Kent"];
    XCTAssertEqual(target.promise.value, @"Kent");

}

- (void)testReentrancy {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];

    KSDeferred *defer = [KSDeferred defer];
    KSPromise *target = defer.promise;
    [target then:^id (NSString * value) {
        NSLog(@"Level 1");
        XCTAssertEqual(value, @"Freddie");

        // now, in the promise completion completion block, somebody calls back into the same KSDeferred
        [target then:^id (NSString * value) {
            NSLog(@"Level 2");
            XCTAssertEqual(value, @"Freddie");
            // rentrant goop
            [expectation fulfill];
            return nil;
        }];

        return nil;
    }];
    [defer resolveWithValue:@"Freddie"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testBrokenMonster {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];

    BrokenMonster *monster = [[BrokenMonster alloc] init];
    [monster.promiseForMonster then:^id (NSString * value) {
        NSLog(@"Monster 1");
        XCTAssertEqual(value, @"Froggie");

        [monster.promiseForMonster then:^id (NSString * value) {
            NSLog(@"Monster 2");
            XCTAssertEqual(value, @"Froggie");
            [expectation fulfill];
            return nil;
        }];
        
        return nil;
    }];

    [monster pokeMonster:@"Froggie"];
    [self waitForExpectationsWithTimeout:1 handler:nil];

}

- (void) testCoolMonster {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];

    CoolMonster *monster = [[CoolMonster alloc] init];
    [monster.promiseForMonster then:^id (NSString * value) {
        NSLog(@"Monster 1");
        XCTAssertEqual(value, @"Froggie");

        [monster.promiseForMonster then:^id (NSString * value) {
            NSLog(@"Monster 2");
            XCTAssertEqual(value, @"Froggie");
            [expectation fulfill];
            return nil;
        }];

        return nil;
    }];

    [monster pokeMonster:@"Froggie"];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
}

@end
