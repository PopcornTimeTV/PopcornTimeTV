

#import "SQSubSetting.h"

@implementation SQSubSetting

-(NSString *) description
{
    return [NSString stringWithFormat:@"size : %f\ntext color: %@\nfont name: %@", self.sizeFloat, self.textColor, self.fontName];

}


+ (id) loadFromDisk
{
    SQSubSetting *subSetting = [[SQSubSetting alloc]init];

    NSData *codedData = [[NSUserDefaults standardUserDefaults]objectForKey:@"subtitleSettings"];
    
    if (!codedData) {
        subSetting.sizeFloat = 56.0;
        subSetting.textColor = [UIColor whiteColor];
        subSetting.fontName = @"system";
        subSetting.backgroundType = SQSubSettingBackgroundNone;
        return subSetting;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:codedData];

}


- (void) writeToDisk
{
    // Write to disk
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    if (data) {
        [[NSUserDefaults standardUserDefaults]setObject:data forKey:@"subtitleSettings"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
    
}


#pragma mark - Attributed String

- (NSDictionary *) attributes
{
    UIFont *font = [UIFont fontWithName:self.fontName size:self.sizeFloat];
    if ([self.fontName isEqual:@"system"]) {
        font = [UIFont systemFontOfSize:self.sizeFloat];
    }
    
    // Paragraph
    float lineSpace = roundf(1.5 * self.sizeFloat);
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineHeightMultiple = lineSpace;
    paragraphStyle.maximumLineHeight  = lineSpace;
    paragraphStyle.minimumLineHeight  = lineSpace;
    paragraphStyle.paragraphSpacingBefore = .0;
    
    return @{NSFontAttributeName : font,
             NSParagraphStyleAttributeName : paragraphStyle,
             NSForegroundColorAttributeName: self.textColor};
}


#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)coder
{
    // Ajuste al protocolo NSCoding
    self = [super init];
    
    if (self) {
        self.sizeFloat = [coder decodeFloatForKey:@"sizeFloat"];
        self.textColor = [coder decodeObjectForKey:@"textColor"];
        self.fontName  = [coder decodeObjectForKey:@"fontName"];
        self.backgroundType = [coder decodeIntegerForKey:@"backgroundType"];
    }
    
    return self;
    
}// initWithCoder


- (void)encodeWithCoder:(NSCoder *)coder
{
    // Ajuste al protocolo NSCoding
    [coder encodeFloat:self.sizeFloat forKey:@"sizeFloat"];
    [coder encodeObject:self.textColor forKey:@"textColor"];
    [coder encodeObject:self.fontName forKey:@"fontName"];
    [coder encodeInteger:self.backgroundType forKey:@"backgroundType"];
    
}// encodeWithCoder

@end
