
#import <CommonCrypto/CommonDigest.h>
#import "MBWebSocketServer.h"														// Originally created by Max Howell in October 2011. This class is in the public domain.

@interface NSString (MBWebSocketServer)	- (id)sha1base64;	@end



@implementation MBWebSocketServer {    GCDAsyncSocket *socket;    NSMutableArray *connections; }		@dynamic clientCount;

-   (id) initWithPort:(NSUI)port delegate:(id<MBWebSocketServerDelegate>)delegate { NSError *error = nil;

	_delegate		= delegate;
	socket			= [GCDAsyncSocket.alloc initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	connections = NSMutableArray.new;

	[socket acceptOnPort:_port = port error:&error];	return error ? (id)(NSLog(@"MBWebSockerServer failed to initialize: %@", error), nil) : self;
}

- (NSUI) clientCount {	return connections.count; }

- (void) send:(id)object { id payload = [object webSocketFrameData]; [connections each:^(ASOCK *conn ){ [conn writeData:payload withTimeout:-1 tag:3]; }]; }



- (NSS*) handshakeResponseForData:(NSData*)data { id(^throw)() = ^{ @throw @"Invalid handshake from client"; return (id)nil; };

	NSA *strings = [NSS stringWithUTF8Data:data].eolines;  /* \r\n */	LOGCOLORS(strings, [NSC randomBrightColor],nil);

	/**
	GET /ws HTTP/1.1
	Host: gravelleconsulting.com
	Upgrade: websocket
	Connection: Upgrade
	Sec-WebSocket-Version: 6
	Sec-WebSocket-Origin: http://gravelleconsulting.com
	Sec-WebSocket-Extensions: deflate-stream
	Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==
	*/

	if (!strings.count || ![strings[0] isEqualToString:@"GET / HTTP/1.1"]) return throw();
	return [strings filterNonNil:^id(NSString *line){		NSArray *parts;

			if((parts = [line componentsSeparatedByString:@":"]).count != 2 || ![parts[0] isEqualToString:@"Sec-WebSocket-Key"]) return nil;

			id							  key = [parts[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

/** As of HyBi 06, the client sends a Sec-WebSocket-Key which is base64 encoded. 
		To this key the magic string "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" is appended, hashed with SHA1 and then base64 encoded. 
		The result is then replied in the header "Sec-WebSocket-Accept". 
		For instance, a string of "x3JJHMbDL1EzLkh9GBhXDw==258EAFA5-E914-47DA-95CA-C5AB0DC85B11" hashed by SHA1 yields a hexadecimal value of 
		
			"1d29ab734b0c9585240069a6e4e3e91b61da1969". */


			id secWebSocketAccept = [key withString:@"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"].sha1base64;

/**	...to which the server responds:
		HTTP/1.1 101 Switching Protocols
		Upgrade: websocket
		Connection: Upgrade
		Sec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=   */

			return JATExpand( @"HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
												 "Upgrade: websocket\r\n"
												 "Connection: Upgrade\r\n"
												 "Sec-WebSocket-Accept: {secWebSocketAccept}\r\n\r\n", secWebSocketAccept);
	}];
}

#pragma mark - GCDAsyncSocketDelegate


- (void)socket:(ASOCK*)sock   didAcceptNewSocket:(ASOCK*)cnxn		{ 	[connections addObject:cnxn]; [cnxn readDataWithTimeout:-1 tag:1]; }		/* didAcceptNewSocket */

- (void)socket:(ASOCK*)cnxn					 didReadData:(NSData*)data
																         withTag:(long)tag			{

	@try {	const unsigned char *bytes = data.bytes;

		if (tag == 1) [cnxn writeData:[self handshakeResponseForData:data].UTF8Data withTimeout:-1 tag:2];

		else if (tag == 4) { /* opcode START */

		/* Defines the interpretation of the "Payload data".  If an unknown opcode is received, the receiving endpoint MUST _Fail the WebSocket Connection_.  The following values are defined.

      *  %x0 denotes a continuation frame
      *  %x1 denotes a text frame
      *  %x2 denotes a binary frame
      *  %x3-7 are reserved for further non-control frames
      *  %x8 denotes a connection close
      *  %x9 denotes a ping
      *  %xA denotes a pong
      *  %xB-F are reserved for further control frames	*/


				uint64_t const  N = bytes[1] & 0x7f;
				char const opcode = bytes[0] & 0x0f;

				if (!bytes[0] & 0x80)	@throw @"Can't decode fragmented frames!";  // TODO support fragmented frames (first bit unset in control frame)
				if (!bytes[1] & 0x80)	@throw @"Can only handle websocket frames with masks!";

				switch (opcode) {
					case 1:
					case 2:
						if (N >= 126) {	[cnxn readDataToLength:N == 126 ? 2 : 8 withTimeout:-1 buffer:nil bufferOffset:0 tag:16 + opcode];
							break;
						}								// ELSE CONTINUE!
					case 8:						// close frame http://tools.ietf.org/html/rfc6455#section-5.5.1
					case 9:						// ping  frame http://tools.ietf.org/html/rfc6455#section-5.5.2
						if (N >= 126) {	// CLOSE with status code 1002 because CONTROL-FRAMES are not allowed to have payloads greater than 125 characters.
							char rsp[4] = {0x88, 2, 0xEA, 0x3};
										[cnxn writeData:[NSData dataWithBytes:rsp length:4] withTimeout:-1 tag:-1];
										[cnxn disconnect];
										LOGCOLORS(@"CLOSE with status code 1002 because CONTROL-FRAMES are not allowed to have payloads greater than 125 characters.",nil);
						} else	[cnxn readDataToLength:N + 4 withTimeout:-1 buffer:nil bufferOffset:0 tag:32 + opcode];
						break;
					default:	@throw @"Cannot handle this websocket frame opcode!";
				}
			} /* opcode END */

			else if (tag == 0x11 || tag == 0x12) {			 uint64_t N; // figure out payload length

				unsigned long long (^ntohll)(unsigned long long) =
			 ^unsigned long long					 (unsigned long long v){ union { unsigned long lv[2]; unsigned long long llv; } u; u.llv = v;	return ((unsigned long long)ntohl(u.lv[0]) << 32) | (unsigned long long)ntohl(u.lv[1]); };

				if		(data.length == 2)	{	uint16_t *p = (uint16_t *)bytes;	N = ntohs(*p) + 4;	}
				else											{	uint64_t *p = (uint64_t *)bytes;	N = ntohll(*p) + 4;	}

				[cnxn readDataToLength:N withTimeout:-1 buffer:nil bufferOffset:0 tag:16 + tag];
			}
			else if (tag == 0x21 || tag == 0x22 || tag == 0x28 || tag == 0x29) { /* read complete payload (0x21) */

				NSMutableData *unmaskedData = [NSMutableData dataWithCapacity:data.length - 4];

				for (int x = 4; x < data.length; ++x) {		char c = bytes[x] ^ bytes[x%4];		[unmaskedData appendBytes:&c length:1];	}

					if			((tag & 0xf) == 1)
						dispatch_async(dispatch_get_main_queue(), ^{ [_delegate webSocketServer:self didReceiveData:unmaskedData fromConnection:cnxn];	});
					else if ((tag & 0xf) == 8) { /*CLOSE*/

						char rsp[4] = {0x88, 2, bytes[1], bytes[0]};	// final two bytes are network-byte-order statusCode that we echo back
						[cnxn writeData:[NSData dataWithBytes:rsp length:4] withTimeout:-1 tag:-1];
					}
					else if ((tag & 0xf) == 9) { /*PING*/

						NSMutableData *pong = unmaskedData.webSocketFrameData.mutableCopy; // FIXME inefficient (but meh)
						((char*)pong.mutableBytes)[0] = 0x8a;
						[cnxn writeData:pong withTimeout:-1 tag:-1];
					}
				[cnxn readDataToLength:2 withTimeout:-1 buffer:nil bufferOffset:0 tag:4];	// configure the cnxn to wait for the next frame
			}
		else 	@throw [NSString stringWithFormat:@"Unhandled tag: %ld", tag];
	}
	@catch (id msg) {
		id err = [NSError errorWithDomain:@"com.methylblue.webSocketServer" code:1 userInfo:@{NSLocalizedDescriptionKey: msg}];
		dispatch_sync(dispatch_get_main_queue(), ^{	[_delegate webSocketServer:self couldNotParseRawData:data fromConnection:cnxn error:err]; });
		[cnxn disconnect]; // FIXME some cases do not require disconnect
	}
}		/* didReadData */

- (void)socket:(ASOCK*)cnxn   didWriteDataWithTag:(long)tag			{		if (tag != 2) return;

		[AZSOQ addOperationWithBlock:^{ [_delegate webSocketServer:self didAcceptConnection:cnxn]; }];

		[cnxn readDataToLength:2 withTimeout:-1 buffer:nil bufferOffset:0 tag:4];

}		/* didWriteDataWithTag */

- (void)socketDidDisconnect:(ASOCK*)cnxn withError:(NSERR*)err	{

	[connections removeObjectIdenticalTo:cnxn];
	[AZSOQ addOperationWithBlock:^{	[_delegate webSocketServer:self clientDisconnected:cnxn];	}];

}   /* socketDidDisconnect */

@end

@implementation																		NSString (MBWebSocketServer)
- (id)sha1base64					{
	NSMutableData* data = (id)self.UTF8Data;
	unsigned char input[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(data.bytes, (unsigned)data.length, input);

	static const char map[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	data = [NSMutableData dataWithLength:28];
	uint8_t* out = (uint8_t*) data.mutableBytes;

	for (int i = 0; i < 20;) {	int v  = 0;
		for (const int N = i + 3; i < N; i++) {	v <<= 8;	v |= 0xFF & input[i]; 	}
		*out++ = map[v >> 18 & 0x3F];
		*out++ = map[v >> 12 & 0x3F];
		*out++ = map[v >>  6 & 0x3F];
		*out++ = map[v >>  0 & 0x3F];
	}
	out[-2] = map[(input[19] & 0x0F) << 2];
	out[-1] = '=';
	return [NSString stringWithData:data encoding:NSASCIIStringEncoding];
}
- (id)webSocketFrameData	{ return self.UTF8Data.webSocketFrameData; }												@end

@implementation																			NSData (MBWebSocketServer)
- (id)webSocketFrameData {	NSMutableData *data = [NSMutableData dataWithLength:10];

	char *header = data.mutableBytes;
	header[0] = 0x81;

	if (self.length > 65535) {
		header[1] = 127;
		header[2] = (self.length >> 56) & 255;
		header[3] = (self.length >> 48) & 255;
		header[4] = (self.length >> 40) & 255;
		header[5] = (self.length >> 32) & 255;
		header[6] = (self.length >> 24) & 255;
		header[7] = (self.length >> 16) & 255;
		header[8] = (self.length >>  8) & 255;
		header[9] = self.length & 255;
	} else if (self.length > 125) {
		header[1] = 126;
		header[2] = (self.length >> 8) & 255;
		header[3] = self.length & 255;
		data.length = 4;
	} else {
		header[1] = self.length;
		data.length = 2;
	}
	[data appendData:self];		return data;
}												@end

@implementation															GCDAsyncSocket (MBWebSocketServer)
- (void)writeWebSocketFrame:(id)object {	[self writeData:[object webSocketFrameData] withTimeout:-1 tag:3];	}					@end
