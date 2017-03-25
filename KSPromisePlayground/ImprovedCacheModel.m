#import "ImprovedCacheModel.h"

@interface ImprovedCacheModel()

@property (nonatomic, strong) NSString *cachedAsset;

@end

@implementation ImprovedCacheModel
-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider {
    self = [super initWithProvider:provider];
    if (self) {
        _currentDeferreds = [NSMutableArray array];
    }
    return self;
}

-(KSPromise *) promiseForAsset {
    KSDeferred *defer = [KSDeferred defer];

    if (self.cachedAsset) {
        [defer resolveWithValue:self.cachedAsset];
        return defer.promise;
    }

    [self.currentDeferreds addObject:defer];
    if (self.currentDeferreds.count > 1) {
        return defer.promise;
    }

    [self.provider.promiseForAsset then:^id (NSString * value) {
        self.cachedAsset = value;
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
