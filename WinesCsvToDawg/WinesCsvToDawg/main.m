//
//  main.m
//  WinesCsvToDawg
//
//  Created by Sergey Yuzepovich on 27.01.15.
//  Copyright (c) 2015 Sergey Yuzepovich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVProcessor.h"
#import "ListBuilder.h"

static NSString *csvFileName;
static NSUInteger splitLen;
static NSUInteger yearStart;
static NSUInteger yearEnd;
static NSString *unicharsetPath = @"./eng.unicharset";
static NSString *wordlist2dawgPath = @"/usr/local/bin/wordlist2dawg";

void printHelp(){
    printf("Usage: WinesCsvToDawg <filename.csv> [options]\n\
\n\
Converts wines csv to tesseract dawg file. Also outputs list of generated words.\n \
\n\
Options:\n\
           -s <len>         split long words into words of <len> characters (at least 4)\n\
           -y <start:end>   include years in range <start:end> (for example 1980:2020)\n\
           -u <unicharset>  path to lang.unicharset tessdata file (by default assumed ./eng.unicharset)\n\
           -w <w2dawg>      wordlist2dawg binary path (default value: /usr/local/bin/wordlist2dawg) \n\
\n");
}

void generateDawg(){
    char command[1000];
    sprintf(command,"%s words.list eng.word-dawg %s", wordlist2dawgPath.UTF8String ,unicharsetPath.UTF8String);
    system(command);
}

void process(){
    NSArray *terms = [CSVProcessor csv: csvFileName filteringNumbers:YES filteringSpecialChars:YES];
    
    NSRange years;
    years.location = yearStart;
    years.length = yearEnd - yearStart;
    
    [ListBuilder buildListOfDictionaryWords:terms includeYears:years splitLongWords:splitLen];
    generateDawg();
}

void terminate(NSString *message){
    NSLog(@"%@ Terminating.",message);
    exit(1);
}

void parseArgs(int argc,const char *argv[]){
    BOOL split;
    BOOL addYears;

    csvFileName = [NSString stringWithUTF8String:argv[1]];
    if(![csvFileName containsString:@"/"]){
        NSString *execPath = [NSString stringWithUTF8String: argv[0]];
        csvFileName = [[execPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:csvFileName];
    }
    
    for(int i=1;i<argc;i++){
        if (strcmp(argv[i], "-s") == 0) {
            split = YES;
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            splitLen = [NSString stringWithUTF8String: argv[i+1]].integerValue;
            if (splitLen < 4) {
                terminate(@"Wrong split length.");
            }
        }
        if (strcmp(argv[i], "-y") == 0) {
            addYears = YES;
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            NSString *s = [NSString stringWithUTF8String: argv[i+1]];
            NSArray *years = [s componentsSeparatedByString:@":"];
            yearStart = [years[0] integerValue];
            yearEnd = [years[1] integerValue];
            if(yearStart <=0 || yearEnd <=0){
                terminate(@"Wrong years.");
            }
        }
        if (strcmp(argv[i], "-u") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            unicharsetPath = [NSString stringWithUTF8String: argv[i+1]];
        }
        if (strcmp(argv[i], "-w") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            wordlist2dawgPath = [NSString stringWithUTF8String: argv[i+1]];
        }

    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        switch (argc) {
            case 1://no args
                printHelp();
                break;
            default:
                parseArgs(argc, argv);
                process();
                break;
        }
    }
    return 0;
}


