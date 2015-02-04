//
//  WinesDatabase.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 28.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "WinesDatabase.h"
#import "CHCSVParser.h"
#import "Wine.h"
#import "Vineyard.h"
#import "Subregion.h"
#import "WineEntity.h"
#import "VineyardEntity.h"
#import "SubregionEntity.h"
#import "G8AppDelegate.h"
#import "BaseEntity+Extensions.h"
#import "DictionariesEntity.h"

static NSString* const DB = @"TermListByWinery";//@"TermListByWineryNewWorldOnly";
static BOOL const IS_COREDATA = YES;

@interface WinesDatabase()<CHCSVParserDelegate>
@property(nonatomic,strong) NSMutableDictionary *wineriesVarieties;
@property(nonatomic,strong) NSMutableDictionary *wineriesVineyards;
@property(nonatomic,strong) NSMutableDictionary *wineriesSubregions;
@property(nonatomic,strong) NSManagedObjectContext *context;

@end

@implementation WinesDatabase{
    NSString *lastKey;
    NSString *lastValue;
    NSUInteger lastLine;
}

+(instancetype)instance{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WinesDatabase alloc]init];
    });
    
    return instance;
}

-(instancetype) init{
    self = [super init];
    if(self){
        _wineriesVarieties = [[NSMutableDictionary alloc]init];
        _wineriesVineyards = [[NSMutableDictionary alloc]init];
        _wineriesSubregions= [[NSMutableDictionary alloc]init];
        _context = [(G8AppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext];
        
        if (IS_COREDATA) {
            [self fetchCoreData];
        }
        else{
            [self fetchCsv];
        }
    }
    return self;
}

-(void)fetchCoreData{
    NSLog(@"Fetching CoreData");
    
    NSError *error;
    NSFetchRequest *fr = [[NSFetchRequest alloc]init];
    NSEntityDescription *e = [NSEntityDescription entityForName:@"DictionariesEntity" inManagedObjectContext:self.context];
    [fr setEntity:e];
    
    NSArray *fetched = [self.context executeFetchRequest:fr error:&error];
    
    if (fetched == nil || fetched.count == 0 || error != nil) {
        NSLog(@"Core data not initialized or corrupted. Will fetch csv");
        [self fetchCsv];
        return;
    }
    
    DictionariesEntity *d = (DictionariesEntity*)fetched[0];
    _wineriesVarieties = d.varieties;
    _wineriesVineyards = d.vineyards;
    _wineriesSubregions = d.subregions;
    NSLog(@"Vars:%lu Vins:%lu Subrs:%lu.",[self.wineriesVarieties count], [self.wineriesVineyards count],[self.wineriesSubregions count]);
}

-(void)fetchCsv{
    NSLog(@"Fetching Csv");
    
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:DB ofType:@"csv"];
    NSInputStream *stream = [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:dbPath]];
    NSStringEncoding encoding=0;
    CHCSVParser *csv = [[CHCSVParser alloc]initWithInputStream:stream usedEncoding:&encoding delimiter:','];
    csv.sanitizesFields = YES;
    csv.trimsWhitespace = YES;
    csv.recognizesBackslashesAsEscapes = YES;
    csv.recognizesComments = YES;
    csv.delegate = self;
    [csv parse];
}

+(NSDictionary*)wineriesAndVarieties{
    return [WinesDatabase instance].wineriesVarieties;
}

+(NSDictionary*)wineriesAndVineyards{
    return [WinesDatabase instance].wineriesVineyards;
}

+(NSDictionary*)wineriesAndSubregions{
    return [WinesDatabase instance].wineriesSubregions;
}


- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex{
    field = [field  stringByTrimmingCharactersInSet: [NSMutableCharacterSet whitespaceAndNewlineCharacterSet]];
    
    switch (fieldIndex) {
        case 0:
            lastKey = field;
            break;
        case 1:
            lastValue = field;
            break;
        case 2:
            if ([field isEqualToString:@"varietal"]) {
                Wine *wine = [[Wine alloc]initWithDisplayName:lastValue];
                [self addObject:wine toDictionary:self.wineriesVarieties byKey:lastKey];
            }
            if ([field isEqualToString:@"vineyard"]) {
                Vineyard *vineyard = [[Vineyard alloc]initWithDisplayName:lastValue];
                [self addObject:vineyard toDictionary:self.wineriesVineyards byKey:lastKey];
            }
            if ([field isEqualToString:@"subregion"]) {
                Subregion *subregion = [[Subregion alloc]initWithDisplayName:lastValue];
                [self addObject:subregion toDictionary:self.wineriesSubregions byKey:lastKey];
            }
            
//            //TODO: refactor
//            if ([field isEqualToString:@"varietal"]) {
//                WineEntity *wine = [NSEntityDescription insertNewObjectForEntityForName:@"WineEntity" inManagedObjectContext:self.context];
//                wine.displayName = lastValue;
//                [wine createShortNamesObjectsFromDisplayNameAndstoreToContext:self.context];
//            }
//            if ([field isEqualToString:@"vineyard"]) {
//                VineyardEntity *vineyard = [NSEntityDescription insertNewObjectForEntityForName:@"VineyardEntity" inManagedObjectContext:self.context];
//                vineyard.displayName = lastValue;
//                [vineyard createShortNamesObjectsFromDisplayNameAndstoreToContext:self.context];
//            }
//            if ([field isEqualToString:@"subregion"]) {
//                SubregionEntity *subregion = [NSEntityDescription insertNewObjectForEntityForName:@"SubregionEntity" inManagedObjectContext:self.context];
//                subregion.displayName = lastValue;
//                [subregion createShortNamesObjectsFromDisplayNameAndstoreToContext:self.context];
//            }

            break;
        default:
            break;
    }
}

-(void) addObject:(id)object toDictionary:(NSMutableDictionary*)dictionary byKey:(NSString*)key{
    if(dictionary[key] == nil){
        dictionary[key] = [NSMutableArray arrayWithObject: object];
    }
    else{
        [dictionary[key] addObject: object];
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error{
    NSLog(@"CSV parser failed with error %s",error.localizedDescription.UTF8String);
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber{
//    NSLog(@"Ended line %lu",recordNumber);
    lastLine = recordNumber;
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser{
}

- (void)parserDidEndDocument:(CHCSVParser *)parser;{
    NSLog(@"CSV parsing done.");
    NSLog(@"Vars:%lu Vins:%lu Subrs:%lu. Lines:%lu",[self.wineriesVarieties count], [self.wineriesVineyards count],[self.wineriesSubregions count],lastLine);
    
    [self deleteAllEntities:@"DictionariesEntity"];
    
    DictionariesEntity *dictsCoreData = [NSEntityDescription insertNewObjectForEntityForName:@"DictionariesEntity" inManagedObjectContext:self.context];
    dictsCoreData.varieties = self.wineriesVarieties;
    dictsCoreData.vineyards = self.wineriesVineyards;
    dictsCoreData.subregions = self.wineriesSubregions;
    
    NSError *error;
    if(![self.context save:&error]){
        NSLog(@"Error saving core data: %@", [error localizedDescription]);
    }
    else{
//        NSFetchRequest *fr = [[NSFetchRequest alloc]init];
//        NSEntityDescription *e = [NSEntityDescription entityForName:@"BaseEntity" inManagedObjectContext:self.context];
//        [fr setEntity:e];
//
//        NSArray *fetched = [self.context executeFetchRequest:fr error:&error];
        NSLog(@"Core data saved successfully."); //Entities:%lu",fetched.count);
    }
}


- (void)deleteAllEntities:(NSString *)nameEntity
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:nameEntity];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error;
    NSArray *fetchedObjects = [self.context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects){
        [self.context deleteObject:object];
    }
    
    error = nil;
    [self.context save:&error];
}


@end
