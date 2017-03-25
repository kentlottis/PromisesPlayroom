#import <Foundation/Foundation.h>
#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface ObviouslyStupidAssetConsumer: AssetProviderBase
@property (nonatomic, strong) NSString *name;
@end


