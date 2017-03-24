//
//  KSPromisePlaygroundTests.m
//  KSPromisePlaygroundTests
//
//  Created by Lottis, Kent on 3/24/17.
//  Copyright © 2017 Lottis, Kent. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSDeferred.h"

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

@end
