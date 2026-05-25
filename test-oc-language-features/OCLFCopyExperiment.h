#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCLFCopyExperimentOutcome : NSObject

@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSArray<NSString *> *lines;

@end

@interface OCLFCopyExperiment : NSObject

- (OCLFCopyExperimentOutcome *)runExperiment;

@end

NS_ASSUME_NONNULL_END
