#import <Foundation/Foundation.h>

#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface BrokenCacheModel: AssetProviderBase
@property (nonatomic, strong) NSMutableArray<KSDeferred *> *currentDeferreds;
@end
