#import <Foundation/Foundation.h>
#import "AssetProviderBase.h"
#import "KSDeferred.h"

@interface StupidAssetConsumer: AssetProviderBase
-(instancetype) initWithName:(NSString *)name provider:(id<AssetProviderProtocol>)provider;
@property (nonatomic, strong) NSString *name;
@end


