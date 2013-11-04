//
//  AppDelegate.h
//  MBWebSocketTest
//
//  Created by Alex Gray on 11/3/13.
//  Copyright (c) 2013 Alex Gray. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBWebSocketServer.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, MBWebSocketServerDelegate>

@property (assign) IBOutlet NSWindow *window;
@property MBWebSocketServer *MBWebSocketServer;
@property Gridly *gridly;
@property (weak) IBOutlet WebView *webView, *webView2;

@end
