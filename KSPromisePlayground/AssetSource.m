#import <Foundation/Foundation.h>
#import "AssetProviderProtocol.h"
#import "AssetSource.h"
#import "KSDeferred.h"


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
