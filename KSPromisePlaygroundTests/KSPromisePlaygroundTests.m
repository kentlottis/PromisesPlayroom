/*
 TODO:
  - Create a NaiveConsumer that combines two promies
  - Build up the repro case so it's more realistic and less obviously broken
 
 */

#import <XCTest/XCTest.h>

#import "AssetProviderProtocol.h"
#import "AssetSource.h"
#import "AssetProviderBase.h"
#import "BrokenCacheModel.h"
#import "ImprovedCacheModel.h"
#import "ObviouslyStupidAssetConsumer.h"
#import "ProperCacheModel.h"
#import "JoinProvider.h"
#import "KSDeferred.h"

@interface KSPromisePlaygroundTests : XCTestCase
@end

@implementation KSPromisePlaygroundTests


// Fails with timeout because the stupid consumer make two requests but the source only has one asset
- (void) testUsingUncachedSourceWithInsufficientAssets {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:source];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Fred");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    [source provideAsset:@"Fred"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Fails with undesired output because the stupid consumer pull two different results from the source instead of using a single value
- (void) testUsingUncachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:source];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Fred");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    [source provideAsset:@"Fred"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Fails in the simple-minded broke cache because of NSEnumerable semantics
- (void) xtestUsingBrokenCachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    BrokenCacheModel *provider = [[BrokenCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Fred");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];
    [source provideAsset:@"Fred"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingFixedCachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ImprovedCacheModel *provider = [[ImprovedCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void) testUsingWorkingCachedSource {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ProperCacheModel *provider = [[ProperCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];
    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Barney"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingWorkingCachedSourceWithIntermediateClear {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ProperCacheModel *provider = [[ProperCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        return nil;
    }];

    [source provideAsset:@"Barney"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        return nil;
    }];

    [provider clearCache];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Fred+Fred");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Fred"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testJoinProviderHappyCase {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *oneSource = [[AssetSource alloc] init];
    AssetSource *anotherSource = [[AssetSource alloc] init];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:oneSource andProvider:anotherSource];

    [oneSource provideAsset:@"Horse"];
    [anotherSource provideAsset:@"Cow"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Cow]");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}
@end
