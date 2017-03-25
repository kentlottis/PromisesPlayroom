#import "ObviouslyStupidAssetConsumer.h"

@implementation ObviouslyStupidAssetConsumer
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
