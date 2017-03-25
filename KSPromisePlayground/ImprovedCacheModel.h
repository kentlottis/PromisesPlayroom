#import <Foundation/Foundation.h>
#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface ImprovedCacheModel: AssetProviderBase
@property (nonatomic, strong) NSMutableArray<KSDeferred *> *currentDeferreds;
@end

