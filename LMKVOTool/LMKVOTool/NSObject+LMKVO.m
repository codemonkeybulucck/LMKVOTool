//
//  NSObject+LMKVO.m
//  LMKVOTool
//
//  Created by lemon on 2018/10/9.
//  Copyright © 2018年 Lemon. All rights reserved.
//

#import "NSObject+LMKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>


static NSString *const LMKVOPREFIX = @"LMKVO";
static NSString *const LMKVOAssociatedObservers = @"LMKVOAssociatedObservers";



@interface LMObserverInfo:NSObject
@property (nonatomic,copy) NSString *key;
@property (nonatomic,weak) id observer;
@property (nonatomic,copy) lmObserveBlock block;
@end

@implementation LMObserverInfo
- (instancetype)initWithObserver:(id)observer key:(NSString *)key block:(lmObserveBlock)block{
    if (self = [super init]) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}
@end

@implementation NSObject (LMKVO)

#pragma mark - method override
static Class kvo_class(id self, SEL _cmd){
    return class_getSuperclass(object_getClass(self));
}

static void kvo_setter(id self, SEL _cmd, id newValue){
    //通过getter方法找出oldValue
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterNameWithSetter:setterName];
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    //调用父类的setter实现，为属性赋值
    void(*objc_sendSuper)(void *,SEL,id) = (void*)objc_msgSendSuper;
    objc_sendSuper(&superClazz,_cmd,newValue);
    //找出所有的观察这，调用block
    NSMutableArray *observers = objc_getAssociatedObject(self,(__bridge const void * _Nonnull)(LMKVOAssociatedObservers));
    for (LMObserverInfo *info in observers) {
        if ([info.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                info.block(self, info.key, oldValue, newValue);
            });
        }
    }
}

#pragma mark - 辅助方法
- (Class)makeNewClassWithClassName:(NSString *)className{
    NSString *kvoClassName = [NSString stringWithFormat:@"%@%@",LMKVOPREFIX,className];
    Class kvoClass = NSClassFromString(kvoClassName);
    //如果已经有该类则直接返回
    if (kvoClass) {
        return kvoClass;
    }
    //否则创建一个新的类
    Class oldClass = object_getClass(self);
    kvoClass = objc_allocateClassPair(oldClass, kvoClassName.UTF8String, 0);
    //模仿系统kvo修改class的实现
    Method classMethod = class_getInstanceMethod(oldClass, @selector(class));
    const char * types = method_getTypeEncoding(classMethod);
    class_addMethod(kvoClass, @selector(class),(IMP)kvo_class, types);
    objc_registerClassPair(kvoClass);
    return  kvoClass;
}

- (BOOL)hasSelector:(SEL)selector{
    Class currentClass = object_getClass(self);
    unsigned int count = 0;
    Method *methodList = class_copyMethodList(currentClass, &count);
    for (int i = 0; i<count; i++) {
       SEL methodSel = method_getName(methodList[i]);
        if (methodSel == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

- (NSString *)getterNameWithSetter:(NSString *)setterName{
    if (setterName.length <=0 || ![setterName hasPrefix:@"set"] || ![setterName hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = NSMakeRange(3, setterName.length -4);
    NSString *key = [setterName substringWithRange:range];
    NSString *firstString = [[key substringToIndex:1] lowercaseString];
    NSString *getterName = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
    return getterName;
}

- (NSString*)setterName:(NSString *)key{
    if (key.length <=0 ) {
        return @"";
    }
    NSString *firstCharacter = [[key substringToIndex:1] uppercaseString];
    NSString *remainString = [key substringFromIndex:1];
    NSString *setterSelector = [NSString stringWithFormat:@"set%@%@:",firstCharacter,remainString];
    return  setterSelector;
}


- (LMObserverInfo*)containsSameObserver:(id)observer key:(NSString *)key{
    NSMutableArray *observers = objc_getAssociatedObject(self,(__bridge const void * _Nonnull)(LMKVOAssociatedObservers));
    LMObserverInfo *specialInfo;
    for (LMObserverInfo *info in observers) {
        if (info.observer == observer && [info.key isEqualToString:key]) {
            specialInfo = info;
            break;
        }
    }
    return specialInfo;
}

#pragma mark - kvo method
- (void)lm_AddObserver:(id)observer
                   key:(NSString *)key
          observeBlock:(lmObserveBlock)block{
    SEL selForSetter = NSSelectorFromString([self setterName:key]);
    Method setterMethod = class_getInstanceMethod([self class], selForSetter);
    //lei判断如果父类不存在setter方法，那么直接返回
    if (!setterMethod) {
        NSLog(@"父类方法不存在setter");
        return;
    }
    //判断对象的isa指针指向的类是否是kvo，如果不是则创建该类的子类，并且将对象的isa指向该子类。
    Class class = object_getClass(self);
    NSString *className = NSStringFromClass(class);
    
    if (![className hasPrefix:LMKVOPREFIX]) {
        //创建一个新的类并且修改isa指针
        class = [self makeNewClassWithClassName:className];
        object_setClass(self, class);
    }
    
    //判断新创建的类是否已经实现了setter方法，如果没有则创建新的setter方法
    if (![self hasSelector:selForSetter]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(class, selForSetter, (IMP)kvo_setter, types);
    }
    //保存observerInfo
    LMObserverInfo *info = [[LMObserverInfo alloc] initWithObserver:observer key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self,(__bridge const void * _Nonnull)(LMKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(LMKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if ([self containsSameObserver:observer key:key]) {
        return;
    }
    [observers addObject:info];
}

- (void)lm_removeObserver:(id)observer
                   key:(NSString*)key{
    NSMutableArray *observers = objc_getAssociatedObject(self,(__bridge const void * _Nonnull)(LMKVOAssociatedObservers));
    LMObserverInfo *specialInfo = [self containsSameObserver:observer key:key];
    if (specialInfo) {
        [observers removeObject:specialInfo];
    }
}

@end
