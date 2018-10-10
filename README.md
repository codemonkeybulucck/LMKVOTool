# LMCustomKVO


## Usage

first: #import "NSObject+LMKVO.h"

second: add observe by calling 

```
- (void)lm_AddObserver:(id)observer
                  key:(NSString *)key
         observeBlock:(lmObserveBlock)block;
         
```
for example :

```
[self.kvoButton lm_AddObserver:self key:@"backgroundColor" observeBlock:^(id observer, NSString *key, id oldValue, id newValue) {
        UIColor *newColor = (UIColor *)newValue;
        [weakSelf.observeButton setBackgroundColor:newColor];
    }];
```

third:remove observe by calling

```
- (void)lm_removeObserver:(id)observer
                   key:(NSString*)key;
```

for example:

```
    [self.kvoButton lm_removeObserver:self key:@"backgroundColor"];
```

[自己动手实现KVO](http://lemon2well.top/2018/10/10/iOS%20开发/iOS动手实现KVO/)
