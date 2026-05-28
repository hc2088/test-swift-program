#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCLFResolveMethodExperimentOutcome : NSObject

@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSArray<NSString *> *lines;

@end

@interface OCLFResolveMethodExperiment : NSObject

- (OCLFResolveMethodExperimentOutcome *)runExperiment;

@end

NS_ASSUME_NONNULL_END
