#import "KSDeferred.h"

@protocol AssetProviderProtocol
-(KSPromise *) promiseForAsset;
@end


