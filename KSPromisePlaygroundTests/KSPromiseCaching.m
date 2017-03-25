/*
 TODO:

 * Set up a convention to easily identify "expected-but-undesirable" behaviors.
   We want all of our tests to pass (normally), but also an easy way of identifying the shortcomings of non-ideal approaches.

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
- (void) xtestUsingBrokenCachedSourceWhenWaiting {
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

- (void) testUsingBrokenCachedSourceWhenPreloaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    BrokenCacheModel *provider = [[BrokenCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];

    [source provideAsset:@"Barney"];
    [source provideAsset:@"Fred"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Fred");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingImprovedCacheSourceWhenWaitingForSource {
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

- (void) testUsingImprovedCacheSourceWhenSourceIsPreloaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ImprovedCacheModel *provider = [[ImprovedCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];
    [source provideAsset:@"Barney"];
    [source provideAsset:@"Fred"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");


        [expectation fulfill];
        return nil;
    }];


    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingProperCachedSource_WhenWaiting {
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

- (void) testUsingProperCachedSource_WhenPreloaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ProperCacheModel *provider = [[ProperCacheModel alloc] initWithProvider:source];
    ObviouslyStupidAssetConsumer * target = [[ObviouslyStupidAssetConsumer alloc] initWithProvider:provider];

    [source provideAsset:@"Barney"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"Barney+Barney");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testUsingProperCachedSourceWithIntermediateClear {
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

- (void) testJoinProviderHappyCaseUncached {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:source andProvider:source];

    [source provideAsset:@"Horse"];
    [source provideAsset:@"Cow"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Cow]");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testJoinProviderHappyCase_WithProperCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    ProperCacheModel *provider = [[ProperCacheModel alloc] initWithProvider:source];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:provider andProvider:provider];

    [source provideAsset:@"Horse"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Horse]");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testJoinProviderHappyCase_WithBrokenCache_WhenPreloaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    BrokenCacheModel *provider = [[BrokenCacheModel alloc] initWithProvider:source];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:provider andProvider:provider];

    [source provideAsset:@"Horse"];
    [source provideAsset:@"Cow"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Horse]");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testJoinProviderHappyCase_WithBrokenCache_WhenWaiting {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    BrokenCacheModel *provider = [[BrokenCacheModel alloc] initWithProvider:source];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:provider andProvider:provider];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Horse]");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Horse"];
    [source provideAsset:@"Cow"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testJoinProviderHappyCase_WithImprovedCache_WhenPreloaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    id<AssetProviderProtocol> provider = [[ImprovedCacheModel alloc] initWithProvider:source];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:provider andProvider:provider];

    [source provideAsset:@"Horse"];
    [source provideAsset:@"Cow"];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Horse]");

        [expectation fulfill];
        return nil;
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void) testJoinProviderHappyCase_WithImprovedCache_WhenWaiting {
    XCTestExpectation *expectation = [self expectationWithDescription:@"promise"];
    AssetSource *source = [[AssetSource alloc] init];
    id<AssetProviderProtocol> provider = [[ImprovedCacheModel alloc] initWithProvider:source];
    JoinProvider *target = [[JoinProvider alloc] initWithProvider:provider andProvider:provider];

    [target.promiseForAsset then:^id (NSString * value) {

        XCTAssertEqualObjects(value, @"[Horse + Horse]");

        [expectation fulfill];
        return nil;
    }];

    [source provideAsset:@"Horse"];
    [source provideAsset:@"Cow"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
