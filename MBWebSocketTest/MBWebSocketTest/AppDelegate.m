//
//  AppDelegate.m
//  MBWebSocketTest
//
//  Created by Alex Gray on 11/3/13.
//  Copyright (c) 2013 Alex Gray. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate { 	NSMutableArray *names; }

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
		_MBWebSocketServer = [MBWebSocketServer.alloc initWithPort:4321 delegate:self];
		names =  [[NSString stringWithContentsOfFile:@"/usr/share/dict/propernames" encoding:NSUTF8StringEncoding error:nil]componentsSeparatedByString:@"\n"].mutableCopy;
		[_webView.mainFrame loadHTMLString:[_gridly = Gridly.new markup] baseURL:nil];
		_webView2.mainFrameURL = @"http://mrgray.com/testsocket.html";

}

- (void) advanceNameWithConnection:(ASOCK*)conn {

	[conn writeWebSocketFrame:[names[0]copy]];// [words dataUsingEncoding:NSUTF8StringEncoding]];
//	NSLog(@"Got \"%@\" from %@", message, socket);
	[names removeObjectAtIndex:0];

}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer didAcceptConnection:(GCDAsyncSocket *)connection{

	[self advanceNameWithConnection:connection];
	NSLog(@"%@", NSStringFromSelector(_cmd));
//	NSString *words =  [NSString stringWithContentsOfFile:@"/usr/share/dict/web2" encoding:NSUTF8StringEncoding error:nil];
//	 @"/Volumes/2T/ServiceData/git/MBWebSocketServer/README.md"

}
//	tmr = [NSTimer timerWithTimeInterval:1.0 target:self
//													 selector:@selector(spit:) userInfo:@[connection,words] repeats:YES];
//	[NSRunLoop.mainRunLoop addTimer:tmr forMode:NSDefaultRunLoopMode];
//}
//- (void) spit:(NSTimer*)t{ NSLog(@"FIRE! %@", t.userInfo[0]);
//
////	 if (![t.userInfo[1]count]) return [t invalidate], NSLog(@"I invalidated!!");
// if (![t.userInfo[1] count]) return [t invalidate], NSLog(@"I invalidated!!");
//	 NSString* x = t.userInfo[1][0];  NSLog(@"X:%@",t.userInfo);
//	[t.userInfo[0] writeWebSocketFrame:x];
//	[t.userInfo[1] removeObjectAtIndex:0];
//
//}


- (void)webSocketServer:(MBWebSocketServer *)webSocketServer clientDisconnected:(GCDAsyncSocket *)connection {

	NSLog(@"%@", NSStringFromSelector(_cmd));
}
- (void)webSocketServer:(MBWebSocketServer *)webSocket didReceiveData:(NSData *)data fromConnection:(GCDAsyncSocket *)connection{
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self advanceNameWithConnection:connection];
}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer couldNotParseRawData:(NSData *)rawData fromConnection:(GCDAsyncSocket *)connection error:(NSError *)error {

	NSLog(@"%@  %@", NSStringFromSelector(_cmd), error);
}

@end
