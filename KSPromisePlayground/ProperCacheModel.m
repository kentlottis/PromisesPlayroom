#import "ProperCacheModel.h"

@implementation ProperCacheModel
-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider {
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


