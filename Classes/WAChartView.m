//  Copyright 2011 WidgetAvenue - Librelio. All rights reserved.


#import "WAChartView.h"

#import "UIView+WAModuleView.h"
#import "WAModuleViewController.h"
#import "NSString+WAURLString.h"
#import "WAParserProtocol.h"


@implementation WAChartView

@synthesize currentViewController,dataForChart, dataForPlot;



#pragma mark -
#pragma mark Lifecycle
- (void)dealloc {
	//SLog(@"Releasing textview");
	[urlString release];
	
    [super dealloc];
}

- (NSString *) urlString
{
    return urlString;
}

- (void) setUrlString: (NSString *) theString
{
    urlString = [[NSString alloc]initWithString: theString];
    
	
    NSString * className = [urlString classNameOfParserOfUrlString];
    Class theClass = NSClassFromString(className);
    NSObject <WAParserProtocol> *parser =  (NSObject <WAParserProtocol> *)[[theClass alloc] init];
    parser.urlString = urlString;
    //SLog(@"parser test %@",[parser getDataAtRow:1 forQueryString:@"Select * from Charts" forDataCol:1]);

    [self constructBarChart];
	
    //Gesture recognizers
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    [doubleTapGestureRecognizer release];

	
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    if ([self isRootModule]){
        [[self firstAvailableUIViewController]  dismissModalViewControllerAnimated:YES];
    }
    else{
       	WAModuleViewController * moduleViewController = [[WAModuleViewController alloc]init];
        moduleViewController.moduleUrlString= urlString;
        moduleViewController.initialViewController= (WAModuleViewController *)[self firstAvailableUIViewController];
        moduleViewController.containingView= self.superview;
        moduleViewController.containingRect= CGRectZero;//This forces full screen
        [moduleViewController pushViewControllerIfNeededAndLoadModuleView];
        [moduleViewController release];
        
        
    }
	
}


- (void)constructScatterPlot
{
	// Create graph from theme
    graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:theme];
    self.hostedGraph = graph;
	
    graph.paddingLeft = 10.0;
	graph.paddingTop = 10.0;
	graph.paddingRight = 10.0;
	graph.paddingBottom = 10.0;
    
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(2.0)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(3.0)];
	
    // Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromString(@"0.5");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval = 2;
 	NSArray *exclusionRanges = [NSArray arrayWithObjects:
								[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.99) length:CPTDecimalFromFloat(0.02)], 
								[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.99) length:CPTDecimalFromFloat(0.02)],
								[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(2.99) length:CPTDecimalFromFloat(0.02)],
								nil];
	x.labelExclusionRanges = exclusionRanges;
	
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPTDecimalFromString(@"0.5");
    y.minorTicksPerInterval = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
	exclusionRanges = [NSArray arrayWithObjects:
					   [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.99) length:CPTDecimalFromFloat(0.02)], 
					   [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.99) length:CPTDecimalFromFloat(0.02)],
					   [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(3.99) length:CPTDecimalFromFloat(0.02)],
					   nil];
	y.labelExclusionRanges = exclusionRanges;
	
    // Create a green plot area
	CPTScatterPlot *dataSourceLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = @"Green Plot";
    
    CPTMutableLineStyle *lineStyle = [[dataSourceLinePlot.dataLineStyle mutableCopy] autorelease];
	lineStyle.lineWidth = 3.f;
    lineStyle.lineColor = [CPTColor greenColor];
	lineStyle.dashPattern = [NSArray arrayWithObjects:[NSNumber numberWithFloat:5.0f], [NSNumber numberWithFloat:5.0f], nil];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
	
	// Put an area gradient under the plot above
    CPTColor *areaColor = [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.8];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = -90.0f;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    dataSourceLinePlot.areaFill = areaGradientFill;
    dataSourceLinePlot.areaBaseValue = CPTDecimalFromString(@"1.75");
	
	// Animate in the new plot, as an example
	dataSourceLinePlot.opacity = 0.0f;
	dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionDecimal;
    [graph addPlot:dataSourceLinePlot];
	
	CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeInAnimation.duration = 5.0f;
	fadeInAnimation.removedOnCompletion = NO;
	fadeInAnimation.fillMode = kCAFillModeForwards;
	fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
	[dataSourceLinePlot addAnimation:fadeInAnimation forKey:@"animateOpacity"];
	
	// Create a blue plot area
	CPTScatterPlot *boundLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
    boundLinePlot.identifier = @"Blue Plot";
    
    lineStyle = [[boundLinePlot.dataLineStyle mutableCopy] autorelease];
	lineStyle.miterLimit = 1.0f;
	lineStyle.lineWidth = 3.0f;
	lineStyle.lineColor = [CPTColor blueColor];
    
    boundLinePlot.dataSource = self;
	boundLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
	boundLinePlot.interpolation = CPTScatterPlotInterpolationHistogram;
	[graph addPlot:boundLinePlot];
	
	// Do a blue gradient
	CPTColor *areaColor1 = [CPTColor colorWithComponentRed:0.3 green:0.3 blue:1.0 alpha:0.8];
    CPTGradient *areaGradient1 = [CPTGradient gradientWithBeginningColor:areaColor1 endingColor:[CPTColor clearColor]];
    areaGradient1.angle = -90.0f;
    areaGradientFill = [CPTFill fillWithGradient:areaGradient1];
    boundLinePlot.areaFill = areaGradientFill;
    boundLinePlot.areaBaseValue = [[NSDecimalNumber zero] decimalValue];    
	
	// Add plot symbols
	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPTColor blackColor];
	CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
	plotSymbol.fill = [CPTFill fillWithColor:[CPTColor blueColor]];
	plotSymbol.lineStyle = symbolLineStyle;
    plotSymbol.size = CGSizeMake(10.0, 10.0);
    boundLinePlot.plotSymbol = plotSymbol;
	
    // Add some initial data
	NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
	NSUInteger i;
	for ( i = 0; i < 60; i++ ) {
		id x = [NSNumber numberWithFloat:1+i*0.05];
		id y = [NSNumber numberWithFloat:1.2*rand()/(float)RAND_MAX + 1.2];
		[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
	}
	self.dataForPlot = contentArray;
}

- (void)constructBarChart
{
    // Create barChart from theme
    barChart = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [barChart applyTheme:theme];
    self.hostedGraph = barChart;
    barChart.plotAreaFrame.masksToBorder = NO;
	
    barChart.paddingLeft = 70.0;
	barChart.paddingTop = 20.0;
	barChart.paddingRight = 20.0;
	barChart.paddingBottom = 80.0;
	
	// Add plot space for horizontal bar charts
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)barChart.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(300.0f)];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(32.0f)];
    
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)barChart.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.majorIntervalLength = CPTDecimalFromString(@"5");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
	x.title = @"X Axis";
    x.titleLocation = CPTDecimalFromFloat(7.5f);
	x.titleOffset = 55.0f;
	
	// Define some custom labels for the data elements
	x.labelRotation = M_PI/4;
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
	NSArray *customTickLocations = [NSArray arrayWithObjects:[NSDecimalNumber numberWithInt:1], [NSDecimalNumber numberWithInt:5], [NSDecimalNumber numberWithInt:10], [NSDecimalNumber numberWithInt:15], nil];
	NSArray *xAxisLabels = [NSArray arrayWithObjects:@"Label A", @"Label B", @"Label C", @"Label D", @"Label E", nil];
	NSUInteger labelLocation = 0;
	NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:[xAxisLabels count]];
	for (NSNumber *tickLocation in customTickLocations) {
		CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText: [xAxisLabels objectAtIndex:labelLocation++] textStyle:x.labelTextStyle];
		newLabel.tickLocation = [tickLocation decimalValue];
		newLabel.offset = x.labelOffset + x.majorTickLength;
		newLabel.rotation = M_PI/4;
		[customLabels addObject:newLabel];
		[newLabel release];
	}
	
	x.axisLabels =  [NSSet setWithArray:customLabels];
	
	CPTXYAxis *y = axisSet.yAxis;
    y.axisLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.majorIntervalLength = CPTDecimalFromString(@"50");
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
	y.title = @"Y Axis";
	y.titleOffset = 45.0f;
    y.titleLocation = CPTDecimalFromFloat(150.0f);
	
    // First bar plot
    CPTBarPlot *barPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor darkGrayColor] horizontalBars:NO];
    barPlot.baseValue = CPTDecimalFromString(@"0");
    barPlot.dataSource = self;
    barPlot.barOffset = CPTDecimalFromFloat(-0.25f);
    barPlot.identifier = @"Bar Plot 1";
    [barChart addPlot:barPlot toPlotSpace:plotSpace];
    
    // Second bar plot
    barPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor blueColor] horizontalBars:NO];
    barPlot.dataSource = self;
    barPlot.baseValue = CPTDecimalFromString(@"0");
    barPlot.barOffset = CPTDecimalFromFloat(16.0f);
    barPlot.barCornerRadius = 2.0f;
    barPlot.identifier = @"Bar Plot 2";
	barPlot.delegate = self;
    [barChart addPlot:barPlot toPlotSpace:plotSpace];
}

- (void)constructPieChart
{
	// Create pieChart from theme
    pieGraph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [pieGraph applyTheme:theme];
    self.hostedGraph = pieGraph;
    pieGraph.plotAreaFrame.masksToBorder = NO;
	
    pieGraph.paddingLeft = 20.0;
	pieGraph.paddingTop = 20.0;
	pieGraph.paddingRight = 20.0;
	pieGraph.paddingBottom = 20.0;
	
	pieGraph.axisSet = nil;
    
    // Prepare a radial overlay gradient for shading/gloss
    CPTGradient *overlayGradient = [[[CPTGradient alloc] init] autorelease];
    overlayGradient.gradientType = CPTGradientTypeRadial;
	overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.0];
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.3] atPosition:0.9];
	overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.7] atPosition:1.0];
	
    // Add pie chart
    piePlot = [[CPTPieChart alloc] init];
    piePlot.dataSource = self;
    piePlot.pieRadius = 130.0;
    piePlot.identifier = @"Pie Chart 1";
	piePlot.startAngle = M_PI_4;
	piePlot.sliceDirection = CPTPieDirectionCounterClockwise;
	piePlot.borderLineStyle = [CPTLineStyle lineStyle];
	piePlot.labelOffset = 5.0;
    piePlot.overlayFill = [CPTFill fillWithGradient:overlayGradient];
    [pieGraph addPlot:piePlot];
    [piePlot release];
	
	// Add some initial data
	NSMutableArray *contentArray = [NSMutableArray arrayWithObjects:[NSNumber numberWithDouble:20.0], [NSNumber numberWithDouble:30.0], [NSNumber numberWithDouble:NAN], [NSNumber numberWithDouble:60.0], nil];
	self.dataForChart = contentArray;	
}

#pragma mark -
#pragma mark CPTBarPlot delegate method

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index
{
	//SLog(@"barWasSelectedAtRecordIndex %d", index);
    
	if ( symbolTextAnnotation ) {
        [barChart.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
        symbolTextAnnotation = nil;
    }
    
    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color = [CPTColor redColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
    // Determine point of symbol in plot coordinates
	
    NSNumber *x = [NSNumber numberWithInt:index];
	NSNumber *y = [self numberForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
	NSArray *anchorPoint = [NSArray arrayWithObjects:x,y , nil];
    
    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:2];
    //NSString *yString = [formatter stringFromNumber:y];
    //SLog(@"yString:%@",yString);
    
    //NSString *yString = @"test ep";

    CPTLayer *sublayer = [CPTLayer layer];
    sublayer.backgroundColor = [UIColor blackColor].CGColor;
    sublayer.shadowOffset = CGSizeMake(0, 3);
    sublayer.cornerRadius = 20.0;
    sublayer.frame = CGRectMake(30, 30, 30, 30);
    CAGradientLayer * shineLayer = [CAGradientLayer layer];
    shineLayer.frame = sublayer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.8f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [sublayer addSublayer:shineLayer];


    //[self.layer addSublayer:sublayer];
	
 
    
    // Now add the annotation to the plot area
    //CPTTextLayer *textLayer = [[[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle] autorelease];

    symbolTextAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:anchorPoint];
	symbolTextAnnotation.contentLayer = sublayer;
    // symbolTextAnnotation.contentLayer.contents = (id) [UIImage imageNamed:@"StoreList.png"].CGImage;
    //symbolTextAnnotation.contentLayer.backgroundColor = [UIColor greenColor].CGColor;
    
    symbolTextAnnotation.displacement = CGPointMake(0.0f, 0.0f);
    [barChart.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation]; 
    
     
	//CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"barOffsetScale"];
	animation.duration = 0.25;
	animation.toValue = [NSNumber numberWithDouble:10.5];
	animation.repeatCount = 1;
	animation.autoreverses = YES;
	animation.removedOnCompletion = YES;
	[plot addAnimation:animation forKey:@"height"];
    
    //[self.hostedGraph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    

}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot 
{
	if ([plot isKindOfClass:[CPTPieChart class]])
		return [self.dataForChart count];
	else if ([plot isKindOfClass:[CPTBarPlot class]])
		return 16;
	else
		return [dataForPlot count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index 
{
    NSDecimalNumber *num = nil;
	if ( [plot isKindOfClass:[CPTPieChart class]] ) {
		if ( index >= [self.dataForChart count] ) return nil;
		
		if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
			num = [self.dataForChart objectAtIndex:index];
		}
		else {
			num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
		}
	}
    else if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
		switch ( fieldEnum ) {
			case CPTBarPlotFieldBarLocation:
				if ( index == 4 ) {
					num = [NSDecimalNumber notANumber];
				}
				else {
					num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
				}
				break;
			case CPTBarPlotFieldBarTip:
				if ( index == 8 ) {
					num = [NSDecimalNumber notANumber];
				}
				else {
					num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:(index+1)*(index+1)];
					if ( [plot.identifier isEqual:@"Bar Plot 2"] ) {
						num = [num decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithString:@"10"]];
					}
				}
				break;
		}
    }
	else {
		if ( index % 8 ) {
			num = [[dataForPlot objectAtIndex:index] valueForKey:(fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y")];
			// Green plot gets shifted above the blue
			if ( [(NSString *)plot.identifier isEqualToString:@"Green Plot"] ) {
				if ( fieldEnum == CPTScatterPlotFieldY ) {
					num = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:[num doubleValue] + 1.0];
				}
			}
		}
		else {
			num = [NSDecimalNumber notANumber];
		}
	}
	
    return num;
}

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSNumber *)index
{
	return nil;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    if ( piePlotIsRotating ) return nil;
    
	static CPTMutableTextStyle *whiteText = nil;
	
	if ( !whiteText ) {
		whiteText = [[CPTMutableTextStyle alloc] init];
		whiteText.color = [CPTColor whiteColor];
	}
	
	CPTTextLayer *newLayer = nil;
	
	if ( [plot isKindOfClass:[CPTPieChart class]] ) {
		switch ( index ) {
			case 0:
				newLayer = (id)[NSNull null];
				break;
			default:
				newLayer = [[[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%u", index] style:whiteText] autorelease];
				break;
		}
	}
	else if ( [plot isKindOfClass:[CPTScatterPlot class]] ) {
		newLayer = [[[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%u", index] style:whiteText] autorelease];
	}
    
	
	return newLayer;
}

#pragma mark -
#pragma mark ModuleView protocol

- (void)moduleViewWillAppear:(BOOL)animated{
	
	
}
- (void) moduleViewDidAppear{
}


- (void) moduleViewWillDisappear:(BOOL)animated{
}



- (void) moduleWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	
}
- (void) moduleWillAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	
}

- (void) jumpToRow:(int)row{
    
}


@end
