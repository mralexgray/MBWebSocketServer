// Originally created by Max Howell in October 2011. This class is in the public domain.

// MBWebSocketServer accepts client connections as soon as it is instantiated.
// Implementated against: http://tools.ietf.org/id/draft-ietf-hybi-thewebsocketprotocol-10

//#import "GCDAsyncSocket.h"
#import <AtoZ/AtoZ.h>
#import <AtoZ/AtoZUmbrella.h>
#ifdef SOCKSRVRD
#undef SOCKSRVRD
#define SOCKSRVRD id<MBWebSocketServerDelegate>
#endif
#ifdef SOCKSRVR
#undef SOCKSRVR
#define SOCKSRVR  MBWebSocketServer
#endif

@protocol		MBWebSocketServerDelegate ;
@interface					MBWebSocketServer : NSObject <GCDAsyncSocketDelegate>

- (id)initWithPort:(NSUInteger)port delegate:(SOCKSRVRD)delegate;

/** Sends this data to all open connections. The object must respond to webSocketFrameData. We provide implementations for NSData and NSString.
		You may like to, eg: provide implementations for NSDictionary, encoding into a JSON string before calling [NSString webSocketFrameData].			*/

- (void)send:(id)object;

@property     (weak) SOCKSRVRD delegate;
@property (readonly)		  NSUI port,
															 clientCount;
@end

@protocol MBWebSocketServerDelegate

- (void) webSocketServer:(SOCKSRVR*)me didAcceptConnection:(ASOCK*)cnxn;
- (void) webSocketServer:(SOCKSRVR*)me  clientDisconnected:(ASOCK*)cnxn;

/** Data is passed to you as it was received from the socket, ie. with header & masked. We disconnect the connection immediately after your delegate call returns.
		This always disconnect behavior sucks and should be fixed, but requires more intelligent error handling, so feel free to fix that. */

- (void) webSocketServer:(SOCKSRVR*)me couldNotParseRawData:(NSData*)rawData fromConnection:(ASOCK*)cnxn error:(NSERR*)error;
- (void) webSocketServer:(SOCKSRVR*)me       didReceiveData:(NSData*)data		 fromConnection:(ASOCK*)cnxn;
@end

@interface															GCDAsyncSocket (MBWebSocketServer)
- (void)writeWebSocketFrame:(id)object;						@end

@interface																		  NSData (MBWebSocketServer)
- (NSData *)webSocketFrameData;									  @end
