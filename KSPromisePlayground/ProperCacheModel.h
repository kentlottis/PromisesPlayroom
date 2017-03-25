#import <Foundation/Foundation.h>
#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface ProperCacheModel: AssetProviderBase
@property (nonatomic, strong) KSDeferred *currentDeferred;
-(void)clearCache;
@end
