//
//  main.m
//  TeachFontsAndWords
//
//  Created by Sergey Yuzepovich on 29.01.15.
//  Copyright (c) 2015 Sergey Yuzepovich. All rights reserved.
//

#import <Foundation/Foundation.h>

//constants
static NSString * const unicharambigs =
@"v1\n\
1	m	2	r n	0\n\
2	r n	1	m	0\n\
1	m	2	i n	0\n\
2	i n	1	m	0\n\
1	d	2	c l	0\n\
2	c l	1	d	0\n\
2	n n	2	r m	0\n\
2	r m	2	n n	0\n\
1	n	2	r i	0\n\
2	r i	1	n	0\n\
2	l i	1	h	0\n\
2	l r	1	h	0\n\
2	i i	1	u	0\n\
2	i i	1	n	0\n\
2	n i	1	m	0\n\
3	i i i	1	m	0\n\
2	l l	1	H	0\n\
2	v v	1	w	0\n\
2	V V	1	W	0\n\
1	t	1	f	0\n\
1	f	1	t	0\n\
1	a	1	o	0\n\
1	o	1	a	0\n\
1	e	1	c	0\n\
1	c	1	e	0\n\
2	r r	1	n	0\n\
1	E	2	f i	0\n\
2	l d	2	k i	0\n\
2	l x	1	h	0\n\
2	x n	1	m	0\n\
2	u x	2	i n	0\n\
1	r	1	t	0\n\
1	d	2	t l	0\n\
2	d i	2	t h	0\n\
2	u r	2	i n	0\n\
2	u n	2	i m	0\n\
1	u	1	a	0\n\
1	0	1	o	0\n\
1	d	2	t r	0\n\
1	n	2	t r	0\n\
1	u	2	t i	0\n\
1	d	2	t i	0\n\
1	n	2	i j	0\n\
1	g	2	i j	0\n";

//command line args
static NSMutableArray *fonts;
static NSString *lang           =       @"eng";
static NSString *words          =       @"./words.list";
static NSString *ptsize         =       @"12";
static NSString *charSpace      =       @"0";
static NSString *boxPadding     =       @"0";
static NSString *fontProperties =       @"./font_properties";

void printHelp(){
    printf("Usage: TeachFontsAndWords <\"font1\" \"font2\" ....> [options]\n\
\n\
Produces training tesseract files for specified font names (should be quoted).\n\
This utility automaticly preprocesses input data and launches text2image, tesseract, unicharset_extractor, shapeclustering, mftraining, cntraining, combine_tessdata utilities to produce ready-to-use traineddata tesseract file. All utilities shoud be present at /usr/local/bin/.\n\
\n\
Options:\n\
           -l   <lng>       language abb (defaults to eng)\n\
           -w   <words>     path to words list file (defaults to ./words.list)\n\
           -sz  <size>      training image letter size in points (defaults to 12)\n\
           -sp  <space>     space between training image letters (default 0)\n\
           -bp  <boxPad>    box padding between bounding boxes (default 0)\n\
           -fp  <fontProp>  font properties file path (default ./font_properties)\n\
           \n");
}

static void terminate(NSString *message){
    NSLog(@"%@ Terminating.",message);
    exit(1);
}

void parseArgs(int argc,const char *argv[]){

    fonts = [[NSMutableArray alloc]init];
    
    int fontsIndex;
    for(fontsIndex=1;fontsIndex<argc;fontsIndex++){
        if(strncmp("-", argv[fontsIndex], strlen("-")) == 0){//first option found
            break;
        }
        else{
            NSString *quotedFontName = [NSString stringWithUTF8String: argv[fontsIndex]];
            [fonts addObject:quotedFontName];
        }
    }
    
    for(int i=fontsIndex;i<argc;i++){
        if (strcmp(argv[i], "-l") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            lang = [NSString stringWithUTF8String: argv[i+1]];
        }
        if (strcmp(argv[i], "-w") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            words = [NSString stringWithUTF8String: argv[i+1]];
        }
        if (strcmp(argv[i], "-sz") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            ptsize = [NSString stringWithUTF8String: argv[i+1]];
        }
        if (strcmp(argv[i], "-sp") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            charSpace = [NSString stringWithUTF8String: argv[i+1]];
        }
        if (strcmp(argv[i], "-bp") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            boxPadding = [NSString stringWithUTF8String: argv[i+1]];
        }
        if (strcmp(argv[i], "-fp") == 0) {
            if(argc <= i+1){
                terminate(@"Too few arguments.");
            }
            fontProperties = [NSString stringWithUTF8String: argv[i+1]];
        }
    }
}

NSString* fontShortname(NSString* fontLongname){
    return [[fontLongname stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

BOOL fileExists(NSString *filename){
    if( [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil] != nil){
        return YES;
    }
    return NO;
}

void generateUnambigs(){
    NSString *filename = [NSString stringWithFormat: @"./%@.unicharambigs", lang];
    
    if( fileExists(filename)){
        NSLog(@"unicharambigs already exists." );
        return;
    }
    [unicharambigs writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


void preprocess(){
    //check font_properties existance
    if( !fileExists(fontProperties)){
        NSLog(@"Error: font_properties file not found" );
        exit(1);
    }

    //create txt file to write words.list contents to
    system("touch ./words.list.tmp");
    
    //write words.list contents to tmp file removing all newline characters
    NSString *fileContents = [NSString stringWithContentsOfFile:words encoding:NSUTF8StringEncoding error:nil];
//    fileContents = [fileContents substringToIndex:1000];//TODO: DEBUG
    NSString *fileContentsNoNewlines = [[[fileContents stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByReplacingOccurrencesOfString:@"\r" withString:@" "] lowercaseString];
    [fileContentsNoNewlines writeToFile:@"./words.list.tmp" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    //TODO: add uppercase words?
    
    //write additional letters to make sure all alphanumeric chars are there
    system("echo \"\n the quick 1983 brown 2004 fox 56 jumps over the 7 lazy dog \" >> ./words.list.tmp");
    system("echo \"\n T  H   E  2013  Q   U   I   C   K   B   R   O   W   N  \n\n F   O   X   J   U   M   P   S   42   O   V   E   R  \n\n  5678   T   H   E   L   A   Z   Y   9   D   O   G   \n\n\n\" >> ./words.list.tmp");
    system("echo \"\n T  H   E   123   Q   U   I   C   K    B   R   O   W   N  \n\n F   O   X   J   U   M   P   S   456   O   V   E   R  \n\n  5678   T   H   E   L   A   Z   Y   7 8 9 0   D   O   G   \n\n\n\" >> ./words.list.tmp");
    system("echo \"\n T  H   E   572   Q   U   I   C   K    B   R   O   W   N \n\n  F   O   X   J   U   M   P   S   438   O   V   E   R   \n\n   619   T   H   E   L   A   Z   Y    0   D   O   G   \n\n\n\" >> ./words.list.tmp");
    system("echo \"\n T  H   E      Q   U   I   C   K    B   R   O   W   N \n\n  F   O   X   J   U   M   P   S    O   V   E   R \n\n   T   H   E   L   A   Z   Y    D   O   G   \" >> ./words.list.tmp");

    generateUnambigs();
    NSLog(@"preprocessing done");
}

void cleanup(){
    //TODO: clean up tmp files from ./
}

void process(){
    //step 0: preprocessing
    preprocess();

    //step 1: generate tiffs and boxes
    for (NSString *font in fonts) {
        NSString *shortname = fontShortname(font);
        NSString *cmd = [NSString stringWithFormat:
        @"/usr/local/bin/text2image --text=%@ --outputbase=%@.%@.exp0 --font=\"%@\" --ptsize=%@ --char_spacing=%@ --xsize=9600 --ysize=7200 --box_padding=%@",@"./words.list.tmp", lang, shortname, font, ptsize, charSpace, boxPadding];
        system(cmd.UTF8String);
    }
    NSLog(@"text2image done");
    
    //step 2: train tesseract
    for (NSString *font in fonts) {
        NSString *shortname = fontShortname(font);
        NSString *cmd = [NSString stringWithFormat:
        @"/usr/local/bin/tesseract %@.%@.exp0.tif %@.%@.exp0.box box.train",lang,shortname,lang,shortname];
        system(cmd.UTF8String);
    }
    NSLog(@"tesseract done");

    //step 3: extract unicharset
    NSString *cmd = [NSString stringWithFormat:@"/usr/local/bin/unicharset_extractor"];
    for (NSString *font in fonts) {
        NSString *shortname = fontShortname(font);
        cmd = [NSString stringWithFormat:@"%@ %@.%@.exp0.box ",cmd,lang,shortname];
    }
    system(cmd.UTF8String);
    NSLog(@"unicharset_extractor done");

    //step 4: mfttraining
    cmd=[NSString stringWithFormat:@"/usr/local/bin/mftraining -F %@ -U unicharset -O %@.unicharset ",fontProperties,lang];
    for (NSString *font in fonts) {
        NSString *shortname = fontShortname(font);
        cmd = [NSString stringWithFormat:@"%@ %@.%@.exp0.box.tr ",cmd,lang,shortname];
    }
    system(cmd.UTF8String);
    NSLog(@"mftraining done");

    //step 5: cntraining
    cmd=[NSString stringWithFormat:@"/usr/local/bin/cntraining"];
    for (NSString *font in fonts) {
        NSString *shortname = fontShortname(font);
        cmd = [NSString stringWithFormat:@"%@ %@.%@.exp0.box.tr ",cmd,lang,shortname];
    }
    system(cmd.UTF8String);
    NSLog(@"cntraining done");

    //step 6: renaming things
    NSArray *srcFiles = @[@"normproto",@"shapetable",@"inttemp",@"pffmtable"];
    for (NSString *src in srcFiles) {
        NSString *cmd = [NSString stringWithFormat:@"mv ./%@ ./%@.%@",src,lang,src];
        system(cmd.UTF8String);
    }
    NSLog(@"normproto done");

    //step 7: combine tessdata
    if(!fileExists([NSString stringWithFormat:@"./%@.word-dawg",lang ])){
        NSLog(@"WARNING! <lang>.word-dawg file is absent! Wont pack it into tessdata!");
    }
    cmd=[NSString stringWithFormat:@"/usr/local/bin/combine_tessdata %@.",lang];
    system(cmd.UTF8String);
    NSLog(@"combine_tessdata done");

    //step 8: clean up
    cleanup();
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
