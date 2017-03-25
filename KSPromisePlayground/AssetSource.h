#import "AssetProviderProtocol.h"
#import "KSDeferred.h"

@interface AssetSource: NSObject<AssetProviderProtocol>
-(void) provideAsset: (NSString *) asset;
@end
