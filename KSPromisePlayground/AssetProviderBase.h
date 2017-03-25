#import <Foundation/Foundation.h>
#import "AssetProviderProtocol.h"
#import "KSDeferred.h"


@interface AssetProviderBase: NSObject<AssetProviderProtocol>

-(instancetype) initWithProvider: (id<AssetProviderProtocol>) provider;
@property (nonatomic, strong) id<AssetProviderProtocol> provider;

@end

