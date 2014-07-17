//
//  DataLoader.m
//  The Arb
//
//  Created by Riley Lundquist on 7/2/14.
//  Copyright (c) 2014 Riley Lundquist. All rights reserved.
//

#import "DataLoader.h"
#import "Connection.h"
#import "TrailDBManager.h"
#import "Constants.h"
#import "StyleManager.h"

@implementation DataLoader

static DataLoader *sharedDataLoader = nil;

+ (DataLoader *)sharedLoader {
    if (sharedDataLoader == nil) {
        sharedDataLoader = [[super allocWithZone:NULL] init];
    }
    return sharedDataLoader;
}

- (id)init {
    if ( (self = [super init]) ) {
        // your custom initialization
    }
    return self;
}

-(void)getTrails {
    NSLog(@"Get Trails");
    if (![TrailDBManager hasTrails]) {
        [self loadTrails];
    } else {
        NSLog(@"DB has trails");
    }
    
    NSMutableDictionary *trailsDict = [[NSMutableDictionary alloc] init];
    NSArray *trails = [TrailDBManager getAllTrails];
    NSLog(@"%d trails", trails.count);

    int i=0;
    for (TrailMO *trail in trails) {
        [trailsDict setObject:trail.polyline forKey:[NSNumber numberWithInt:i]];
        i++;
    }
    
    NSLog(@"%d in dictionary", trailsDict.count);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TRAILS_LOADED object:self userInfo:trailsDict];
}

-(void)loadTrails {
    NSLog(@"Load Trails");
    NSMutableDictionary *paths = [[NSMutableDictionary alloc] init];
    NSArray *points = [TrailDBManager getAllPoints];
    
    for (TrailPointMO *point in points) {
        GMSMutablePath *path;
        if ((path = [paths objectForKey:point.trail_id]) == nil) {
            path = [[GMSMutablePath alloc] init];
            [paths setObject:path forKey:point.trail_id];
        }
        [path addLatitude:[point.latitude doubleValue] longitude:[point.longitude doubleValue]];
        NSLog(@"Point: %@, %@", point.latitude, point.longitude);
    }
    
    NSEnumerator *enumerator = [paths keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        GMSPath *path = [paths objectForKey:key];
        GMSPolyline *trail = [GMSPolyline polylineWithPath:path];
        [trail setStrokeColor:[StyleManager getGreenColor]];
        [trail setStrokeWidth:2];
        [TrailDBManager insert:nil color:nil trail_id:key polyline:trail];
    }
    
    /*NSData *trailPointsResponse = [Connection makeRequestFor:@"trail_points"];
     NSString *responseString = [[NSString alloc] initWithData:trailPointsResponse encoding:NSASCIIStringEncoding];
     
     NSError *error = NULL;
     NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"-?\\d+[.]\\d+" options:NSRegularExpressionCaseInsensitive error:&error];
     NSArray *matches = [regex matchesInString:responseString options:0 range:NSMakeRange(0, responseString.length)];
     
     NSTextCheckingResult *latMatch, *lonMatch;
     NSString *latString, *lonString;
     int entry = [TrailDBManager getAllPoints].count;
     for (int i=0; i<matches.count; i+=2) {
     latMatch = matches[i];
     lonMatch = matches[i+1];
     latString = [responseString substringWithRange:[latMatch rangeAtIndex:0]];
     lonString = [responseString substringWithRange:[lonMatch rangeAtIndex:0]];
     
     [TrailDBManager insert:[NSNumber numberWithInt:entry] trail_id:nil latitude:latString longitude:lonString];
     
     NSLog(@"Entry: %d", entry);
     entry++;
     }
     
     NSXMLParser *parser = [[NSXMLParser alloc] initWithData:trailPointsResponse];
     [parser setDelegate:self];
     BOOL result = [parser parse];
     
     NSLog(@"Success? %d", result);*/
}

-(void)getBoundary {
    NSError *error = nil;
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"LAABoundary" ofType:@"csv"];
    NSString* fileContents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:&error];
    NSArray* lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    GMSMutablePath *path = [GMSMutablePath path];
    
    for(int i=1; i<lines.count; i++) {
        NSString* current = [lines objectAtIndex:i];
        NSArray* arr = [current componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        NSString *latitude = [[NSString alloc] initWithFormat:@"%@", [arr objectAtIndex:2]];
        NSString *longitude = [[NSString alloc] initWithFormat:@"%@", [arr objectAtIndex:1]];
    
        [path addLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
        NSLog(@"Border point: %@, %@", latitude, longitude);
    }
    
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:path, @"boundary", nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOUNDARY_LOADED object:self userInfo:userInfo];
}



/*-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqualToString:@"rtept"]) {
        [TrailDBManager insert:[NSNumber numberWithUnsignedInteger:[TrailDBManager numberOfPoints]] trail_id:[attributeDict objectForKey:@"trail"] latitude:[attributeDict objectForKey:@"lat"] longitude:[attributeDict objectForKey:@"lon"]];
    }
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"Error: %@", parseError);
}*/

@end
