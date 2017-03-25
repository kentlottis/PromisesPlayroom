//
//  KSPromisePlaygroundTests.m
//  KSPromisePlaygroundTests
//
//  Created by Lottis, Kent on 3/24/17.
//  Copyright © 2017 Lottis, Kent. All rights reserved.
//


/* 
 TODO:
  - Split each of the classes up into files
  - Rename the StupidConsumer to ObviouslyStupidConsumer
  - Create a NaiveConsumer that combines two promies
  - Build up the repro case so it's more realistic and less obviously broken
 
 */

#import <XCTest/XCTest.h>

#import "AssetProviderProtocol.h"
#import "AssetSource.h"
#import "AssetProviderBase.h"
#import "BrokenCacheModel.h"
#import "CorrectedCacheModel.h"
#import "StupidAssetConsumer.h"
#import "WorkingCacheModel.h"
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

- (void)xtestExample {
    KSDeferred *target = [KSDeferred defer];
    [target resolveWithValue:@"Kent"];
    XCTAssertEqual(target.promise.value, @"Kent");

}

- (void)xtestReentrancy {
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

- (void) xtestBrokenMonster {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *provider = [[AssetSource alloc] init];

    BrokenCacheModel *monster = [[BrokenCacheModel alloc] initWithProvider:provider];
    [monster.promiseForAsset then:^id (NSString * value) {
        NSLog(@"Monster 1");
        XCTAssertEqual(value, @"Froggie");

        [monster.promiseForAsset then:^id (NSString * value) {
            NSLog(@"Monster 2");
            XCTAssertEqual(value, @"Froggie");
            [expectation fulfill];
            return nil;
        }];
        
        return nil;
    }];

    [provider provideAsset:@"Froggie"];
    [self waitForExpectationsWithTimeout:1 handler:nil];

}

- (void) xtestCoolMonster {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *provider = [[AssetSource alloc] init];

    WorkingCacheModel *monster = [[WorkingCacheModel alloc] initWithProvider:provider];
    [monster.promiseForAsset then:^id (NSString * value) {
        NSLog(@"Monster 1");
        XCTAssertEqualObjects(value, @"Kermit");

        [monster.promiseForAsset then:^id (NSString * value) {
            NSLog(@"Monster 2");
            XCTAssertEqualObjects(value, @"Kermit");
            [expectation fulfill];
            return nil;
        }];

        return nil;
    }];

    [provider provideAsset:@"Kermit"];
    [self waitForExpectationsWithTimeout:10000 handler:nil];
}

// Fails with timeout because the stupid consumer make two requests but the source only has one asset
- (void) testUsingUncachedSourceWithInsufficientAssets {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    StupidAssetConsumer * target = [[StupidAssetConsumer alloc] initWithName:@"Uncached" provider:source];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    XCTAssertEqual(source.totalPromises, 1);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Fails with undesired output because the stupid consumer pull two different results from the source instead of using a single value
- (void) testUsingUncachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    StupidAssetConsumer * target = [[StupidAssetConsumer alloc] initWithName:@"Uncached" provider:source];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    [source provideAsset:@"Fred"];
    XCTAssertEqual(source.totalPromises, 1);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Fails in the simple-minded broke cache because of NSEnumerable semantics
- (void) testUsingBrokenCachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    BrokenCacheModel *provider = [[BrokenCacheModel alloc] initWithProvider:source];
    StupidAssetConsumer * target = [[StupidAssetConsumer alloc] initWithName:@"Broken" provider:provider];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    XCTAssertEqual(source.totalPromises, 1);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingFixedCachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    FixedCacheModel *provider = [[FixedCacheModel alloc] initWithProvider:source];
    StupidAssetConsumer * target = [[StupidAssetConsumer alloc] initWithName:@"Broken" provider:provider];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    XCTAssertEqual(source.totalPromises, 1);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void) testUsingWorkingCachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    WorkingCacheModel *provider = [[WorkingCacheModel alloc] initWithProvider:source];
    StupidAssetConsumer * target = [[StupidAssetConsumer alloc] initWithName:@"Working" provider:provider];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    XCTAssertEqual(source.totalPromises, 1);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingWorkingCachedSourceWithIntermediateClear {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    WorkingCacheModel *provider = [[WorkingCacheModel alloc] initWithProvider:source];
    StupidAssetConsumer * target = [[StupidAssetConsumer alloc] initWithName:@"Working" provider:provider];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        return nil;
    }];

    [source provideAsset:@"Barney"];
    XCTAssertEqual(source.totalPromises, 1);

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        return nil;
    }];

    XCTAssertEqual(source.totalPromises, 1);
    
    [provider clearCache];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Fred+Fred");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Fred"];
    XCTAssertEqual(source.totalPromises, 2);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
