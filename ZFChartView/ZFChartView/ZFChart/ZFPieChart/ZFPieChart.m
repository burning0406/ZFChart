//
//  ZFPieChart.m
//  ZFChartView
//
//  Created by apple on 16/3/21.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ZFPieChart.h"
#import "ZFPie.h"
#import "ZFConst.h"
#import "NSString+Zirkfied.h"
#import "UIView+Zirkfied.h"
#import "ZFTranslucencePath.h"

@interface ZFPieChart()

/** 存储value的数组 */
@property (nonatomic, strong) NSMutableArray * valueArray;
/** 存储名称的数组 */
@property (nonatomic, strong) NSMutableArray * nameArray;
/** 存储颜色的数组 */
@property (nonatomic, strong) NSMutableArray * colorArray;
/** 存储开始角度的数组 */
@property (nonatomic, strong) NSMutableArray * startAngleArray;
/** 存储结束角度的数组 */
@property (nonatomic, strong) NSMutableArray * endAngleArray;
/** 存储每个圆弧动画开始的时间 */
@property (nonatomic, strong) NSMutableArray * startTimeArray;
/** 动画总时长 */
@property (nonatomic, assign) CFTimeInterval totalDuration;
/** 半径 */
@property (nonatomic, assign) CGFloat radius;
/** 半径最大上限 */
@property (nonatomic, assign) CGFloat maxRadius;
/** 总数 */
@property (nonatomic, assign) CGFloat totalValue;
/** 记录每个圆弧开始的角度 */
@property (nonatomic, assign) CGFloat startAngle;
/** 记录valueArray当前元素的下标 */
@property (nonatomic, assign) NSInteger index;
/** 记录当前path的中心点 */
@property (nonatomic, assign) CGPoint centerPoint;
/** 记录bezier线宽 */
@property (nonatomic, assign) CGFloat lineWidth;
/** 记录圆环中心 */
@property (nonatomic, assign) CGPoint pieCenter;
/** 半透明Path延伸长度 */
@property (nonatomic, assign) CGFloat extendLength;
/** 记录self初始高度 */
@property (nonatomic, assign) CGFloat originHeight;


/** 主题Label */
@property (nonatomic, strong) UILabel * topicLabel;

@end

@implementation ZFPieChart

- (NSMutableArray *)colorArray{
    if (!_colorArray) {
        _colorArray = [NSMutableArray array];
    }
    return _colorArray;
}

- (NSMutableArray *)startAngleArray{
    if (!_startAngleArray) {
        _startAngleArray = [NSMutableArray array];
    }
    return _startAngleArray;
}

- (NSMutableArray *)endAngleArray{
    if (!_endAngleArray) {
        _endAngleArray = [NSMutableArray array];
    }
    return _endAngleArray;
}

- (NSMutableArray *)startTimeArray{
    if (!_startTimeArray) {
        _startTimeArray = [NSMutableArray array];
    }
    return _startTimeArray;
}

/**
 *  初始化属性
 */
- (void)commonInit{
    _maxRadius = self.frame.size.width > self.frame.size.height ? self.frame.size.height : self.frame.size.width;
    _radius = _maxRadius * ZFPieChartCirqueRatio;
    _piePatternType = kPieChartPatternTypeForCirque;
    _isShadow = YES;
    _isShowPercent = YES;
    _isShowDetail = NO;
    _isAnimated = YES;
    _startAngle = ZFRadian(-90);
    _totalDuration = 0.75f;
    _percentOnChartFontSize = 10.f;
    _extendLength = _radius * ZFPieChartCirqueRatio;
    _originHeight = self.frame.size.height;
    _pieCenter = CGPointMake(self.center.x, CGRectGetHeight(self.topicLabel.frame) + NAVIGATIONBAR_HEIGHT + _radius);
    self.backgroundColor = ZFWhite;
    self.bounces = NO;
    self.showsHorizontalScrollIndicator = NO;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        //标题Label
        self.topicLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 30)];
        self.topicLabel.font = [UIFont boldSystemFontOfSize:18.f];
        self.topicLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.topicLabel];
        
        [self commonInit];
    }
    
    return self;
}

/**
 *  添加详情
 */
- (void)addUI{
    for (NSInteger i = 0; i < self.valueArray.count; i++) {
        CGFloat height = 25;
        CGFloat yPos = _piePatternType == kPieChartPatternTypeForCirque ? _pieCenter.y + _radius * 1.75 + height * i : _pieCenter.y + _radius * 2.4 + height * i;
        
        //装载容器
        UIView * background = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, self.frame.size.width, height)];
        background.tag = PieChartDetailBackgroundTag + i;
        [self addSubview:background];
        
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTranslucencePathAction:)];
        [background addGestureRecognizer:tap];
        
        //颜色View
        UIView * color = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * 0.05, 5, 10, 10)];
        [color setBorderCornerRadius:color.frame.size.width * 0.5 andBorderWidth:0 andBorderColor:nil];
        color.backgroundColor = _colorArray[i];
        [background addSubview:color];
        
        CGFloat width = (self.frame.size.width * (1 - 0.1) - 40) / 3.f;
        CGFloat gap = (SCREEN_WIDTH - CGRectGetMaxX(color.frame) - 10 - self.frame.size.width * 0.05 - 3 * width) / 2;
        
        //名称
        UILabel * name = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(color.frame) + 10, 0, width, 20)];
        name.text = _nameArray[i];
        name.font = [UIFont boldSystemFontOfSize:16.f];
        [background addSubview:name];
        
        //数值
        UILabel * value = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(name.frame) + gap, 0, width, 20)];
        value.text = _valueArray[i];
        value.font = [UIFont boldSystemFontOfSize:16.f];
        [background addSubview:value];
        
        //百分比
        UILabel * percent = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(value.frame) + gap, 0, width, 20)];
        percent.text = [self getPercent:i];
        percent.font = [UIFont boldSystemFontOfSize:16.f];
        [background addSubview:percent];
    }
    
    //重设self.frame的值
    UILabel * lastLabel = (UILabel *)[self viewWithTag:PieChartDetailBackgroundTag + self.valueArray.count - 1];
    self.contentSize = CGSizeMake(self.frame.size.width, CGRectGetMaxY(lastLabel.frame) + 20);
}

/**
 *  饼图每部分的shapeLayer
 *
 *  @param center         中心点
 *  @param startAngle     开始角度
 *  @param endAngle       结束角度
 *  @param color          颜色
 *  @param duration       动画执行时间
 *  @param piePatternType 饼图类型
 *
 *  @return CAShapeLayer
 */
- (CAShapeLayer *)pieShapeLayerWithCenter:(CGPoint)center startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle color:(UIColor *)color duration:(CFTimeInterval)duration piePatternType:(kPiePatternType)piePatternType{
    
    ZFPie * pie = [ZFPie pieWithCenter:center radius:_radius startAngle:startAngle endAngle:endAngle color:color duration:duration piePatternType:piePatternType isAnimated:_isAnimated];
    pie.isShadow = _isShadow;
    _lineWidth = pie.lineWidth;
    return pie;
}

#pragma mark - 半透明Path

/**
 *  半透明Path
 *
 *  @param startAngle 开始角度
 *  @param endAngle   结束角度
 *  @param index      下标
 *
 *  @return ZFTranslucencePath
 */
- (ZFTranslucencePath *)translucencePathShapeLayerWithStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle index:(NSInteger)index{
    ZFTranslucencePath * layer = [ZFTranslucencePath layerWithArcCenter:_pieCenter radius:_radius + _extendLength * 0.5 startAngle:startAngle endAngle:endAngle clockwise:YES];
    layer.strokeColor = [_colorArray[index] CGColor];
    layer.lineWidth = _lineWidth + _extendLength;
    
    return layer;
}

#pragma mark - 清除控件

/**
 *  清除之前所有子控件
 */
- (void)removeAllSubLayers{
    [self.startAngleArray removeAllObjects];
    [self.endAngleArray removeAllObjects];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, _originHeight);
    
    NSArray * subLayers = [NSArray arrayWithArray:self.layer.sublayers];
    for (CALayer * layer in subLayers) {
        if (layer != self.topicLabel.layer) {
            [layer removeAllAnimations];
            [layer removeFromSuperlayer];
        }
    }
    
    NSArray * subviews = [NSArray arrayWithArray:self.subviews];
    for (UIView * view in subviews) {
        if (view != self.topicLabel) {
            [view removeFromSuperview];
        }
    }
}

/**
 *  移除半透明Path
 */
- (void)removeZFTranslucencePath{
    NSArray * sublayers = [NSArray arrayWithArray:self.layer.sublayers];
    for (CALayer * layer in sublayers) {
        if ([layer isKindOfClass:[ZFTranslucencePath class]]) {
            [layer removeFromSuperlayer];
        }
    }
}

#pragma mark - public method

/**
 *  重绘
 */
- (void)strokePath{
    [self removeAllSubLayers];
    [self removeZFTranslucencePath];
    
    if ([self.dataSource respondsToSelector:@selector(valueArrayInPieChart:)]) {
        self.valueArray = [NSMutableArray arrayWithArray:[self.dataSource valueArrayInPieChart:self]];
    }
    
    if ([self.dataSource respondsToSelector:@selector(nameArrayInPieChart:)]) {
        self.nameArray = [NSMutableArray arrayWithArray:[self.dataSource nameArrayInPieChart:self]];
    }
    
    if ([self.dataSource respondsToSelector:@selector(colorArrayInPieChart:)]) {
        self.colorArray = [NSMutableArray arrayWithArray:[self.dataSource colorArrayInPieChart:self]];
    }
    
    //若为整圆样式，则改变半径大小
    if (_piePatternType == kPieChartPatternTypeForCircle) {
        _radius = _maxRadius * ZFPieChartCircleRatio;
    }
    
    for (NSInteger i = 0; i < _valueArray.count; i++) {
        //有动画
        if (_isAnimated) {
            NSDictionary * userInfo = @{@"index":@(i)};
            NSTimer * timer = [NSTimer timerWithTimeInterval:[self.startTimeArray[i] floatValue] target:self selector:@selector(timerAction:) userInfo:userInfo repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }else{//无动画
            [self showEachPieShapeLayer:i];
        }
    }
    
    if (_nameArray) {
        _isShowDetail ? [self addUI] : nil;
    }
}

#pragma mark - 定时器

- (void)timerAction:(NSTimer *)sender{
    _index = [[sender.userInfo objectForKey:@"index"] integerValue];
    [self showEachPieShapeLayer:_index];
    
    [sender invalidate];
    sender = nil;
}

#pragma mark - 添加饼图

/**
 *  添加饼图每个shapeLayer
 */
- (void)showEachPieShapeLayer:(NSInteger)i{
    //计算每个item所占角度大小
    CGFloat angle = [self countAngle:[_valueArray[i] floatValue]];
    [self.layer addSublayer:[self pieShapeLayerWithCenter:_pieCenter startAngle:_startAngle endAngle:_startAngle + angle color:_colorArray[i] duration:[self countDuration:i] piePatternType:_piePatternType]];
    _centerPoint = [self getBezierPathCenterPointWithStartAngle:_startAngle endAngle:_startAngle + angle];
    
    [_startAngleArray addObject:@(_startAngle)];
    [_endAngleArray addObject:@(_startAngle + angle)];
    //临时记录下一个path的开始角度
    _startAngle += angle;
    
    _isShowPercent ? [self creatPercentLabel:i] : nil;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if (point.y > _pieCenter.y + _radius + 60) {
        return;
    }
    
    //求弧度
    CGFloat x = (point.x - _pieCenter.x);
    CGFloat y = (point.y - _pieCenter.y);
    CGFloat radian = atan2(y, x);
    //当超过180度时，要加2π
    if (y < 0 && x < 0) {
        radian = radian + ZFRadian(360);
    }
    
    //判断点击位置的角度在哪个path范围上
    for (NSInteger i = 0; i < _startAngleArray.count; i++) {
        CGFloat startAngle = [_startAngleArray[i] floatValue];
        CGFloat endAngle = [_endAngleArray[i] floatValue];

        if (radian >= startAngle && radian < endAngle) {
            [self removeZFTranslucencePath];
            [self.layer addSublayer:[self translucencePathShapeLayerWithStartAngle:startAngle endAngle:endAngle index:i]];
            UILabel * percentLabel = [self viewWithTag:PieChartPercentLabelTag + i];
            [self bringSubviewToFront:percentLabel];
            
            return;
        }
    }
}

#pragma mark - 显示半透明Path Action

/**
 *  显示半透明Path Action
 *
 *  @param sender UITapGestureRecognizer
 */
- (void)showTranslucencePathAction:(UITapGestureRecognizer *)sender{
    NSInteger index = sender.view.tag - PieChartDetailBackgroundTag;
    CGFloat startAngle = [_startAngleArray[index] floatValue];
    CGFloat endAngle = [_endAngleArray[index] floatValue];
    
    [self removeZFTranslucencePath];
    [self.layer addSublayer:[self translucencePathShapeLayerWithStartAngle:startAngle endAngle:endAngle index:index]];
    UILabel * percentLabel = [self viewWithTag:PieChartPercentLabelTag + index];
    [self bringSubviewToFront:percentLabel];
}

#pragma mark - 计算每个item所占角度大小

/**
 *  计算每个item所占角度大小
 *
 *  @param value 每个item的value
 *
 *  @return 返回角度大小
 */
- (CGFloat)countAngle:(CGFloat)value{
    //计算百分比
    CGFloat percent = value / _totalValue;
    //需要多少度的圆弧
    CGFloat angle = M_PI * 2 * percent;
    return angle;
}

#pragma mark - 计算每个部分执行动画持续时间

/**
 *  计算每个圆弧执行动画持续时间
 *
 *  @param index 下标
 *
 *  @return CFTimeInterval
 */
- (CFTimeInterval)countDuration:(NSInteger)index{
    if (_totalDuration < 0.1f) {
        _totalDuration = 0.1f;
    }
    float count = _totalDuration / 0.1f;
    CGFloat averageAngle =  M_PI * 2 / count;
    CGFloat time = [self countAngle:[_valueArray[index] floatValue]] / averageAngle * 0.1;
    
    return time;
}

#pragma mark - 获取每个path的中心点

/**
 *  获取每个path的中心点
 *
 *  @return CGFloat
 */
- (CGPoint)getBezierPathCenterPointWithStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle{
    //一半角度(弧度)
    CGFloat halfAngle = (endAngle - startAngle) / 2;
    //中心角度(弧度)
    CGFloat centerAngle = halfAngle + startAngle;
    //中心角度(角度)
    CGFloat realAngle = ZFAngle(centerAngle);
    
    CGFloat center_xPos = ZFCos(realAngle) * _radius + _pieCenter.x;
    CGFloat center_yPos = ZFSin(realAngle) * _radius + _pieCenter.y;
    
    return CGPointMake(center_xPos, center_yPos);
}

#pragma mark - 添加百分比Label

/**
 *  添加百分比Label
 */
- (void)creatPercentLabel:(NSInteger)i{
    NSString * string = [self getPercent:i];
    CGRect rect = [string stringWidthRectWithSize:CGSizeMake(0, 0) fontOfSize:_percentOnChartFontSize isBold:YES];
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    label.text = string;
    label.alpha = 0.f;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:_percentOnChartFontSize];
    label.center = _centerPoint;
    label.tag = PieChartPercentLabelTag + i;
    [self addSubview:label];
    
    [UIView animateWithDuration:[self countDuration:i] animations:^{
        label.alpha = 1.f;
    }];
    
    //获取r,g,b三色值
    CGFloat red = [_colorArray[i] red];
    CGFloat green = [_colorArray[i] green];
    //path颜色为深色时，更改文字颜色
    if ((red < 180.f && green < 180.f)) {
        label.textColor = [UIColor whiteColor];
    }
}

/**
 *  计算百分比
 *
 *  @return NSString
 */
- (NSString *)getPercent:(NSInteger)index{
    CGFloat percent = [_valueArray[index] floatValue] / _totalValue * 100;
    NSString * string;
    if (self.percentType == kPercentTypeDecimal) {
        string = [NSString stringWithFormat:@"%.2f%%",percent];
    }else if (self.percentType == kPercentTypeInteger){
        string = [NSString stringWithFormat:@"%d%%",(int)roundf(percent)];
    }
    return string;
}

#pragma mark - 重写setter,getter方法

- (void)setValueArray:(NSMutableArray *)valueArray{
    _valueArray = valueArray;
    _totalValue = 0;
    [self.startTimeArray removeAllObjects];
    CFTimeInterval startTime = 0.f;
    
    //计算总数
    for (NSInteger i = 0; i < valueArray.count; i++) {
        _totalValue += [valueArray[i] floatValue];
    }
    
    //计算每个path的开始时间
    for (NSInteger i = 0; i < valueArray.count; i++) {
        [self.startTimeArray addObject:[NSNumber numberWithDouble:startTime]];
        CFTimeInterval duration = [self countDuration:i];
        startTime += duration;
    }
}

- (void)setTopic:(NSString *)topic{
    _topic = topic;
    self.topicLabel.text = _topic;
}

@end
