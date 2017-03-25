#import "BrokenCacheModel.h"

@implementation BrokenCacheModel
-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider {
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
