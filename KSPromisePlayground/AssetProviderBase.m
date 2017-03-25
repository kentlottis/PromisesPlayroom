#import "AssetProviderBase.h"

@implementation AssetProviderBase

-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider {
    self = [super init];
    if (self) {
        _provider = provider;
    }

    return self;
}

-(KSPromise *)promiseForAsset {
    // Needs to be implemented by base classes
    assert(false);
    return nil;
}

@end


