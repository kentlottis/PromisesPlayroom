#import <Foundation/Foundation.h>
#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface FixedCacheModel: AssetProviderBase
@property (nonatomic, strong) NSMutableArray<KSDeferred *> *currentDeferreds;
@end

