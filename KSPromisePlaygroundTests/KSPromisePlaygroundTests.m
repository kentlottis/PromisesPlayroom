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
#import "KSDeferred.h"

@protocol AssetProviderProtocol
-(KSPromise *) promiseForAsset;
@end

@interface AssetSource: NSObject<AssetProviderProtocol>
-(void) provideAsset: (NSString *) asset;
@property (nonatomic, assign, readonly) NSInteger totalPromises;
@end

@interface AssetSource()
@property (nonatomic, assign, readwrite) NSInteger totalPromises;
@property (nonatomic, strong) KSDeferred *deferred;
@property (nonatomic, strong) NSMutableArray<NSString*>*assetQueue;
@property (nonatomic, strong) NSMutableArray<KSDeferred*>*deferredQueue;
@end

@implementation AssetSource
-(instancetype) init {
    self = [super init];
    if (self) {
        _deferred = [KSDeferred defer];
        _assetQueue = [NSMutableArray array];
        _deferredQueue = [NSMutableArray array];
        _totalPromises = 0;
    }
    return self;
}

-(KSPromise *) promiseForAsset {
    KSDeferred *deferred = [KSDeferred defer];
    [self.deferredQueue addObject:deferred];
    [self resolvePromises];
    self.totalPromises += 1;
    return deferred.promise;
}

-(void) provideAsset: (NSString *) asset {
    [self.assetQueue addObject:asset];
    [self resolvePromises];
}

-(void) resolvePromises {
    while (self.assetQueue.count > 0 && self.deferredQueue.count > 0) {
        NSString *asset = self.assetQueue.firstObject;
        KSDeferred *defer = self.deferredQueue.firstObject;
        [self.assetQueue removeObjectAtIndex:0];
        [self.deferredQueue removeObjectAtIndex:0];
        [defer resolveWithValue:asset];
    }
}

@end

@interface AssetProviderBase: NSObject<AssetProviderProtocol>
-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider;
@property (nonatomic, strong) id<AssetProviderProtocol> provider;
@end

@implementation AssetProviderBase

-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider {
    self = [super init];
    if (self) {
        _provider = provider;
    }

    return self;
}

-(KSPromise *)promiseForAsset {
    assert(false);
    return nil;
}

@end


@interface BrokenCacheModel: AssetProviderBase
@property (nonatomic, strong) NSMutableArray<KSDeferred *> *currentDeferreds;
@end

@implementation BrokenCacheModel
-(instancetype) initWithProvider: (AssetSource *) provider {
    self = [super initWithProvider:provider];
    if (self) {
        _currentDeferreds = [NSMutableArray array];
    }
    return self;
}

-(KSPromise *) promiseForAsset {
    KSDeferred *defer = [KSDeferred defer];

    [self.currentDeferreds addObject:defer];
    if (self.currentDeferreds.count > 1) {
        return defer.promise;
    }

    [self.provider.promiseForAsset then:^id (NSString * value) {
        for (KSDeferred *defer in self.currentDeferreds) {
            [defer resolveWithValue:value];
        }
        [self.currentDeferreds removeAllObjects];
        return nil;
    }];

    return defer.promise;
}

@end

@interface FixedCacheModel: AssetProviderBase
@property (nonatomic, strong) NSMutableArray<KSDeferred *> *currentDeferreds;
@end

@implementation FixedCacheModel
-(instancetype) initWithProvider: (AssetSource *) provider {
    self = [super initWithProvider:provider];
    if (self) {
        _currentDeferreds = [NSMutableArray array];
    }
    return self;
}

-(KSPromise *) promiseForAsset {
    KSDeferred *defer = [KSDeferred defer];

    [self.currentDeferreds addObject:defer];
    if (self.currentDeferreds.count > 1) {
        return defer.promise;
    }

    [self.provider.promiseForAsset then:^id (NSString * value) {
        while (self.currentDeferreds.count > 0) {
            KSDeferred *defer = self.currentDeferreds.firstObject;
            [defer resolveWithValue:value];
            [self.currentDeferreds removeObjectAtIndex:0];
        }
        return nil;
    }];

    return defer.promise;
}

@end


@interface WorkingCacheModel: AssetProviderBase
@property (nonatomic, strong) KSDeferred *currentDeferred;
-(void)clearCache;
@end

@implementation WorkingCacheModel
-(instancetype) initWithProvider: (AssetSource *) provider {
    self = [super initWithProvider:provider];
    if (self) {
    }
    return self;
}

-(void) clearCache {
    self.currentDeferred = nil;
}

-(KSPromise *) promiseForAsset {
    if (self.currentDeferred) {
        return self.currentDeferred.promise;
    }

    KSDeferred *defer = [KSDeferred defer];
    self.currentDeferred = defer;

    [self.provider.promiseForAsset then:^id (NSString * value) {
        [self.currentDeferred resolveWithValue:value];
        return nil;
    }];

    return defer.promise;
}

@end


@interface StupidAssetConsumer: AssetProviderBase
-(instancetype) initWithName:(NSString *)name provider:(id<AssetProviderProtocol>)provider;
@property (nonatomic, strong) NSString *name;
@end

@implementation StupidAssetConsumer
-(instancetype) initWithName:(NSString *)name provider:(id<AssetProviderProtocol>)provider {
    self = [super initWithProvider:provider];
    if (self) {
        _name = name;
    }
    return self;
}

-(KSPromise *) promiseForAsset {
    KSDeferred *deferred = [KSDeferred defer];

    [self.provider.promiseForAsset then:^id (NSString * value1) {
        [self.provider.promiseForAsset then:^id (NSString * value2) {
            NSString *combined = [NSString stringWithFormat:@"%@+%@", value1, value2];
            [deferred resolveWithValue:combined];
            return nil;
        }];

        return nil;
    }];

    return deferred.promise;
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
