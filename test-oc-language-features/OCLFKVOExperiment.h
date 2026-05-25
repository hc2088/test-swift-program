#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCLFKVOExperimentOutcome : NSObject

@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSArray<NSString *> *lines;

@end

@interface OCLFKVOExperiment : NSObject

- (OCLFKVOExperimentOutcome *)runExperiment;

@end

NS_ASSUME_NONNULL_END
