#import <Foundation/Foundation.h>
#import "AssetProviderProtocol.h"
#import "KSDeferred.h"

@interface JoinProvider: NSObject<AssetProviderProtocol>
- (instancetype) initWithProvider:(id<AssetProviderProtocol>)provider andProvider:(id<AssetProviderProtocol>)otherProvider;
@end

