//
//  NSDate+ZKAdditions.m
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import "NSDate+ZKAdditions.h"

typedef NS_OPTIONS(NSUInteger, ZKCalendarUnit)
{
    ZKCalendarUnitEra                = kCFCalendarUnitEra,
    ZKCalendarUnitYear               = kCFCalendarUnitYear,
    ZKCalendarUnitMonth              = kCFCalendarUnitMonth,
    ZKCalendarUnitDay                = kCFCalendarUnitDay,
    ZKCalendarUnitHour               = kCFCalendarUnitHour,
    ZKCalendarUnitMinute             = kCFCalendarUnitMinute,
    ZKCalendarUnitSecond             = kCFCalendarUnitSecond,
};

@implementation NSDate (ZKAdditions)

+ (NSDate *) zk_dateWithDosDate:(NSUInteger)dosDate {
	NSUInteger date = (NSUInteger)(dosDate >> 16);
	NSDateComponents *comps = [NSDateComponents new];
	comps.year = ((date & 0x0FE00) / 0x0200) + 1980;
	comps.month = (date & 0x1E0) / 0x20;
	comps.day = date & 0x1f;
	comps.hour = (dosDate & 0xF800) / 0x800;
	comps.minute = (dosDate & 0x7E0) / 0x20;
	comps.second = 2 * (dosDate & 0x1f);
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (UInt32) zk_dosDate {
	NSUInteger options = ZKCalendarUnitYear | ZKCalendarUnitMonth | ZKCalendarUnitDay |
    ZKCalendarUnitHour | ZKCalendarUnitMinute | ZKCalendarUnitSecond;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:options fromDate:self];
	return ((UInt32)(comps.day + 32 * comps.month + 512 * (comps.year - 1980)) << 16) | (UInt32)(comps.second / 2 + 32 * comps.minute + 2048 * comps.hour);
}

@end