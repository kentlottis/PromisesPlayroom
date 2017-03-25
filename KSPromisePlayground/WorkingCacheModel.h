#import <Foundation/Foundation.h>
#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface WorkingCacheModel: AssetProviderBase
@property (nonatomic, strong) KSDeferred *currentDeferred;
-(void)clearCache;
@end
