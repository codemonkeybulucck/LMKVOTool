//
//  ViewController.m
//  LMKVOTool
//
//  Created by lemon on 2018/10/9.
//  Copyright © 2018年 Lemon. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+LMKVO.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *kvoButton;
@property (weak, nonatomic) IBOutlet UIButton *observeButton;

- (IBAction)changeButtonColor:(id)sender;
- (IBAction)addObserve:(id)sender;
- (IBAction)removeObserve:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)addObserve:(id)sender {
    //系统KVO
    //[self.kvoButton addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
    //自定义KVO
    __weak typeof(self)weakSelf = self;
    [self.kvoButton lm_AddObserver:self key:@"backgroundColor" observeBlock:^(id observer, NSString *key, id oldValue, id newValue) {
        UIColor *newColor = (UIColor *)newValue;
        [weakSelf.observeButton setBackgroundColor:newColor];
    }];
}

//系统KVO
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
//    UIColor *color = change[NSKeyValueChangeNewKey];
//    [self.observeButton setBackgroundColor:color];
//}

- (IBAction)removeObserve:(id)sender {
    //系统KVO
    //[self.kvoButton removeObserver:self forKeyPath:@"backgroundColor"];
    [self.kvoButton lm_removeObserver:self key:@"backgroundColor"];
}

- (IBAction)changeButtonColor:(id)sender {
    int number1 = arc4random_uniform(256);
    int number2 = arc4random_uniform(256);
    int number3 = arc4random_uniform(256);
    UIColor *color = [UIColor colorWithRed:number1/255.0 green:number2/255.0 blue:number3/255.0 alpha:1];
    [sender setBackgroundColor:color];
}
@end
