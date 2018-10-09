//
//  NSObject+LMKVO.h
//  LMKVOTool
//
//  Created by lemon on 2018/10/9.
//  Copyright © 2018年 Lemon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^lmObserveBlock)(id observer, NSString *key ,id oldValue, id newValue);

@interface NSObject (LMKVO)
- (void)lm_AddObserver:(id)observer
                  key:(NSString *)key
         observeBlock:(lmObserveBlock)block;

- (void)lm_removeObserver:(id)observer
                   key:(NSString*)key;
@end
