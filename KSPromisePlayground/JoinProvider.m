#import "JoinProvider.h"

@interface JoinProvider()
@property (nonatomic, strong) id<AssetProviderProtocol> oneProvider;
@property (nonatomic, strong) id<AssetProviderProtocol> otherProvider;
@end

@implementation JoinProvider

- (instancetype) initWithProvider:(id<AssetProviderProtocol>)provider
                      andProvider:(id<AssetProviderProtocol>)otherProvider {
    self = [super init];
    if (self) {
        _oneProvider = provider;
        _otherProvider = otherProvider;
    }

    return self;
}

-(KSPromise *) promiseForAsset {
    KSDeferred *defer = [KSDeferred defer];

    [self.oneProvider.promiseForAsset then:^id (NSString * oneValue) {
        [self.otherProvider.promiseForAsset then:^id (NSString * anotherValue) {
            NSString *joinedValue = [NSString stringWithFormat:@"[%@ + %@]", oneValue, anotherValue];
            [defer resolveWithValue:joinedValue];

            return nil;
        }];

        return nil;
    }];

    return defer.promise;
}
@end
