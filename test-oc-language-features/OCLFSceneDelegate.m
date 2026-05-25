#import "OCLFSceneDelegate.h"
#import "OCLFViewController.h"

@implementation OCLFSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];

    OCLFViewController *rootViewController = [[OCLFViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];

    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.whiteColor;
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.13 green:0.19 blue:0.30 alpha:1.0]
    };
    appearance.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.08];

    navigationController.navigationBar.standardAppearance = appearance;
    navigationController.navigationBar.scrollEdgeAppearance = appearance;
    navigationController.navigationBar.compactAppearance = appearance;
    if (@available(iOS 15.0, *)) {
        navigationController.navigationBar.compactScrollEdgeAppearance = appearance;
    }
    navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.13 green:0.42 blue:0.95 alpha:1.0];
    navigationController.navigationBar.translucent = NO;

    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
}

@end
