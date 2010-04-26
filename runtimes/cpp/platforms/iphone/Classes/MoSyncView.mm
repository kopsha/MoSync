/* Copyright (C) 2009 Mobile Sorcery AB
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

#import "MoSyncView.h"
#include "MosyncMain.h"

#include "iphone_helpers.h"

#include "Platform.h"
#include "Syscall.h"


static MoSyncView *currentScreen;

@interface UIApplication(MyExtras) 
- (void)terminateWithSuccess; 
@end

@interface MessageBoxHandler : UIViewController <UIAlertViewDelegate> {
	BOOL kill;
	NSString *msg;
}
@property BOOL kill;
@property (copy, nonatomic) NSString* msg;
- (void)alertViewCancel:(UIAlertView *)alertView;
@end

@implementation MessageBoxHandler
@synthesize kill;
@synthesize msg;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(kill)
		Exit();
}
- (void)alertViewCancel:(UIAlertView *)alertView {
	// don't know if this is allowed...
	if(kill)
		Exit();
}
@end

// Used to pass parameters to the widgets, through performSelectorOnMainThread
@interface WidgetHandler : UIViewController <UITextFieldDelegate> {
	NSString *msg;
	int x,y,l,h, widgetId, rsc;
}
@property (copy, nonatomic) NSString* msg;
@property int x,y,l,h, widgetId, rsc;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
@end

@implementation WidgetHandler
@synthesize msg;
@synthesize x,y,l,h, widgetId, rsc;
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}
@end



@implementation MoSyncView


- (void)updateMoSyncView:(CGImageRef)ref {
	mosyncView = ref;
	[self performSelectorOnMainThread : @ selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.clearsContextBeforeDrawing = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
		[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];

		self.frame.origin.y = 0;
		mosyncView = nil;
        // Initialization code
		MoSyncMain(self.frame.size.width, self.frame.size.height, self);
    }
    return self;
}

/*
- (void)mTimerProcess{
	DoneUpdatingMoSyncView();
} 
*/

- (void)drawRect:(CGRect)rect {
	if(mosyncView == nil) return;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, rect, mosyncView);	
	DoneUpdatingMoSyncView();
	/*
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.000001f
													  target:self
													selector:@selector(mTimerProcess)
													userInfo:nil
													 repeats:NO];
	[timer fire];
	*/
	 
}


- (void)dealloc {
    [super dealloc];
}

bool down = false;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSSet *allTouches = [event allTouches];
	UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
	CGPoint point = [touch locationInView:self];

	if(!down) {
		Base::gEventQueue.addPointerEvent(point.x, point.y, EVENT_TYPE_POINTER_PRESSED);
		down = true;
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	NSSet *allTouches = [event allTouches];
	UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
	CGPoint point = [touch locationInView:self];
	
	if(down) {
		Base::gEventQueue.addPointerEvent(point.x, point.y, EVENT_TYPE_POINTER_DRAGGED);
	}	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSSet *allTouches = [event allTouches];
	UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
	CGPoint point = [touch locationInView:self];
	
	if(down) {
		Base::gEventQueue.addPointerEvent(point.x, point.y, EVENT_TYPE_POINTER_RELEASED);	
		down = false;
	}	
}

-(void) messageBox:(id) obj {
	MessageBoxHandler *mbh = (MessageBoxHandler*) obj;
	UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:nil
                          message:mbh.msg
                          delegate:mbh
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
	
    [alert show];
    [alert release];
}
 
-(void) showMessageBox: (NSString*)msg shouldKill: (bool)kill {
	MessageBoxHandler *mbh = [MessageBoxHandler alloc];
	mbh.kill = kill;
	mbh.msg = msg;
	[self performSelectorOnMainThread: @ selector(messageBox:) withObject:(id)mbh waitUntilDone:NO];
}

-(void) addLabel:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	UILabel *myLabel = [[UILabel alloc] initWithFrame:CGRectMake(wh.x, wh.y, wh.l, wh.h)];
	myLabel.text = wh.msg;
	myLabel.backgroundColor = [UIColor clearColor];
	//myLabel.font = [UIFont systemFontOfSize:12];
	myLabel.opaque = NO;
	myLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
	myLabel.textAlignment = UITextAlignmentCenter;
	myLabel.textColor = [UIColor darkGrayColor];
	[self addSubview:myLabel];
}

-(void) showLabel: (NSString*) msg posX:(int) x posY:(int) y length:(int) l height:(int) h widgetId:(int) widgetid {
	WidgetHandler *wh = [WidgetHandler alloc];
	wh.msg = msg;
	wh.x = x;
	wh.y = y;
	wh.l = l;
	wh.h = h;
	wh.widgetId = widgetid;
	[self performSelectorOnMainThread: @ selector(addLabel:) withObject:(id)wh waitUntilDone:NO];
	
}

-(void) addButton:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = CGRectMake(wh.x, wh.y, wh.l, wh.h);
	[button setTitle:wh.msg forState:UIControlStateNormal];
	button.tag = wh.widgetId;
	[button addTarget:self action:@selector(passEvent:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:button];
	
	
}

-(void) showButton: (NSString*) msg posX:(int) x posY:(int) y length:(int) l height:(int) h widgetId:(int) widgetid {
	WidgetHandler *wh = [WidgetHandler alloc];
	wh.msg = msg;
	wh.x = x;
	wh.y = y;
	wh.l = l;
	wh.h = h;
	wh.widgetId = widgetid;
	[self performSelectorOnMainThread: @ selector(addButton:) withObject:(id)wh waitUntilDone:NO];
	
}

-(void) addTextField:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(wh.x, wh.y, wh.l, wh.h)];
	textField.placeholder = wh.msg;
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.delegate = wh;
	//textField.rightViewMode = UITextFieldViewModeAlways;
	//UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	//textField.rightView = button;
	//[button addTarget:self action:@selector(hideKeyboard:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:textField];
	
	
}

-(void) showTextField: (NSString*) msg posX:(int) x posY:(int) y length:(int) l height:(int) h widgetId:(int) widgetid {
	WidgetHandler *wh = [WidgetHandler alloc];
	wh.msg = msg;
	wh.x = x;
	wh.y = y;
	wh.l = l;
	wh.h = h;
	wh.widgetId = widgetid;
	[self performSelectorOnMainThread: @ selector(addTextField:) withObject:(id)wh waitUntilDone:NO];
}

- (void)navigationBar:(UINavigationBar*)bar buttonClicked:(int)button
{
    if (button == 1)
    {
		[self.superview sendSubviewToBack:currentScreen];
		//[self.superview sendSubviewToBack:self];
        NSLog(@"Navigation bar back button clicked.");
    }

}

//Action methods for toolbar buttons:
- (void) pressButton1:(id)sender {
	//Actionsheet
	/*UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Menu" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"test", nil];
	[actionSheet showInView:self];
	[actionSheet release];*/
	NSLog(@"+ button clicked.");
}

-(void) addScreen:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	MoSyncView *v = [[MoSyncView alloc] initWithFrame:self.frame];
	v.tag = wh.widgetId;
	[self addSubview:v ];
	v.backgroundColor = [UIColor groupTableViewBackgroundColor];
	//v.backgroundColor = [UIColor whiteColor];
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	currentScreen = v;
	//currentScreen = self;
	Base::gEventQueue.addNativeUIEvent([v tag], 0);
	NSLog(@"the tag value is: %d", [v tag]);
}

-(MoSyncView *) showScreen:(int) widgetid {
	WidgetHandler *wh = [WidgetHandler alloc];
	wh.widgetId = widgetid;
	[self performSelectorOnMainThread: @ selector(addScreen:) withObject:(id)wh waitUntilDone:YES];
	return currentScreen;
}

-(void) addNavigationBar:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	UINavigationBar *nav = [[UINavigationBar alloc] 
							initWithFrame: CGRectMake(0.0f, 20.0f, self.frame.size.width, 48.0f)];
    [nav showButtonsWithLeftTitle: @"Back" 
				   rightTitle: nil leftBack: YES];
	CGRect frame = CGRectMake(0, 0, 320, 48);
	UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont boldSystemFontOfSize:20.0];
	label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.text = wh.msg;
	[nav addSubview:label];
    [nav setDelegate: self];
	[self addSubview:nav];
}

-(void) showNavigationBar: (NSString*) msg {
	WidgetHandler *wh = [WidgetHandler alloc];
	wh.msg = msg;
	[self performSelectorOnMainThread: @ selector(addNavigationBar:) withObject:(id)wh waitUntilDone:NO];
	
}

-(void) addToolBar:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	toolbar = [UIToolbar new];
	toolbar.barStyle = UIBarStyleDefault;
	[toolbar sizeToFit];
	toolbar.frame = CGRectMake(0, /*(self.frame.size.height - 44)*/480-44, self.frame.size.width, 44);
	[self addSubview:toolbar];
}

-(void) showToolBar {
	WidgetHandler *wh = [WidgetHandler alloc];
	[self performSelectorOnMainThread: @ selector(addToolBar:) withObject:(id)wh waitUntilDone:NO];
}

-(void) addToolBarItem:(id) obj {
	WidgetHandler *wh = (WidgetHandler*) obj;
	Surface* img = Base::gSyscall->resources.get_RT_IMAGE(wh.rsc);	
	UIBarButtonItem *systemItem1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:img->image]
																	style:UIBarButtonItemStylePlain target:self action:@selector(passEvent:)];
	systemItem1.tag = wh.widgetId;
	[items addObject: systemItem1];
	[toolbar setItems:items animated:YES];
}

-(void) showToolBarItem: (int) widgetid withIcon: (int) rsc {
	WidgetHandler *wh = [WidgetHandler alloc];
	wh.widgetId = widgetid;
	wh.rsc = rsc;
	items = [NSMutableArray arrayWithCapacity:1];
	[self performSelectorOnMainThread: @ selector(addToolBarItem:) withObject:(id)wh waitUntilDone:NO];
	
}

-(void) passEvent:(id) obj {

	Base::gEventQueue.addNativeUIEvent([obj tag], 0);
	NSLog(@"the tag value is: %d", [obj tag]);
	
}



@end