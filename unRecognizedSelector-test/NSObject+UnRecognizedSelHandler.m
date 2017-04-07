//
//  NSObject+UnRecognizedSelHandler.m
//  SpaceHome
//
//  Created by ccSunday on 2017/3/23.
//
//

#import "NSObject+UnRecognizedSelHandler.h"
#import <objc/runtime.h>

//提示框--->UIAlertController
#define ALERT_VIEW(Title,Message,Controller) {UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:Title message:Message preferredStyle:UIAlertControllerStyleAlert];        [alertVc addAction:action];[Controller presentViewController:alertVc animated:YES completion:nil];}

#import "AppDelegate.h"
static NSString *_errorFunctionName;
void dynamicMethodIMP(id self,SEL _cmd){
#ifdef DEBUG
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIViewController *currentRootViewController = delegate.window.rootViewController;
    NSString *error = [NSString stringWithFormat:@"errorClass->:%@\n errorFuction->%@\n errorReason->UnRecognized Selector",NSStringFromClass([self class]),_errorFunctionName];
    ALERT_VIEW(@"程序异常",error,currentRootViewController);
#else
    //upload error
    
#endif
    
}
#pragma mark 方法调换
static inline void change_method(Class _originalClass ,SEL _originalSel,Class _newClass ,SEL _newSel){
    Method methodOriginal = class_getInstanceMethod(_originalClass, _originalSel);
    Method methodNew = class_getInstanceMethod(_newClass, _newSel);
    method_exchangeImplementations(methodOriginal, methodNew);
}

@implementation NSObject (UnRecognizedSelHandler)
+ (void)load{
    
    change_method([self class], @selector(methodSignatureForSelector:), [self class], @selector(SH_methodSignatureForSelector:));
    
    change_method([self class], @selector(forwardInvocation:), [self class], @selector(SH_forwardInvocation:));
}

- (NSMethodSignature *)SH_methodSignatureForSelector:(SEL)aSelector{
    if (![self respondsToSelector:aSelector]) {
        _errorFunctionName = NSStringFromSelector(aSelector);
        NSMethodSignature *methodSignature = [self SH_methodSignatureForSelector:aSelector];
        if (class_addMethod([self class], aSelector, (IMP)dynamicMethodIMP, "v@:")) {//方法参数的获取存在问题
            NSLog(@"临时方法添加成功！");
        }
        if (!methodSignature) {
            methodSignature = [self SH_methodSignatureForSelector:aSelector];
        }
        
        return methodSignature;
        
    }else{
        return [self SH_methodSignatureForSelector:aSelector];
    }
}

- (void)SH_forwardInvocation:(NSInvocation *)anInvocation{
    SEL selector = [anInvocation selector];
    if ([self respondsToSelector:selector]) {
        [anInvocation invokeWithTarget:self];
    }else{
        [self SH_forwardInvocation:anInvocation];
    }
}
@end
