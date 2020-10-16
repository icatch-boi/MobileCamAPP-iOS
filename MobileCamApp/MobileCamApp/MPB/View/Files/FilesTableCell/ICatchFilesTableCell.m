//
//  ICatchFilesTableCell.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/9.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFilesTableCell.h"
#import "MPBCommonHeader.h"

@interface ICatchFilesTableCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *createTimeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *selectedImgView;

@end

@implementation ICatchFilesTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
//    self.thumbnailImgView.backgroundColor = [UIColor orangeColor];
    self.selectedImgView.backgroundColor = RGB_HEX(0xF2F2F2, 1.0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFileInfo:(ICatchFileInfo *)fileInfo {
    _fileInfo = fileInfo;
    
    self.nameLabel.text = [NSString stringWithFormat:@"%s", fileInfo.file->getFileName().c_str()];
    self.sizeLabel.text = [self translateSize:fileInfo.file->getFileSize()>>10];
    self.createTimeLabel.text = [self translateDate:fileInfo.file->getFileDate()];//[NSString stringWithFormat:@"%s", file->getFileDate().c_str()];
    if (fileInfo.file->getFileType() == ICH_FILE_TYPE_VIDEO) {
        self.durationLabel.text = [self translateSecond:fileInfo.file->getFileDuration()];
        AppLog(@"%@ %@ %@ %@", self.nameLabel.text, self.durationLabel.text, self.createTimeLabel.text, self.sizeLabel.text);
    } else {
        self.durationLabel.text = @"";
        AppLog(@"%@ %@ %@", self.nameLabel.text, self.sizeLabel.text, self.createTimeLabel.text);
    }
    
    _selectedImgView.image = fileInfo.selected ? [UIImage imageNamed:@"ic_done_red_24dp"] : [UIImage imageNamed:@"ic_done_gray_24dp"];
    self.backgroundColor = fileInfo.selected ? RGB_HEX(0xDFDFDF, 1.0) : self.superview.backgroundColor;
}

- (void)setEditState:(BOOL)editState {
    _selectedImgView.hidden = !editState;
}

- (void)setThumbnail:(UIImage *)thumbnail {
    _thumbnail = thumbnail;
    
    self.thumbnailImgView.image = thumbnail;
}

- (NSString *)translateSize:(unsigned long long)sizeInKB
{
    NSString *humanDownloadFileSize = nil;
    double temp = (double)sizeInKB/1024; // MB
    if (temp > 1024) {
        temp /= 1024;
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fGB", temp];
    } else {
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fMB", temp];
    }
    return humanDownloadFileSize;
}

- (NSString *)translateDate:(string)date {
    NSMutableString *dateStr = [NSMutableString string];
    
    NSString *dateString = [NSString stringWithFormat:@"%s", date.c_str()];
    //AppLogDebug(AppLogTagAPP, @"dateString: %@", dateString);
    
    if (dateString.length == 15) {
//        [dateStr appendString:[dateString substringWithRange:NSMakeRange(0, 4)]];
//        [dateStr appendString:@"-"];
//        [dateStr appendString:[dateString substringWithRange:NSMakeRange(4, 2)]];
//        [dateStr appendString:@"-"];
//        [dateStr appendString:[dateString substringWithRange:NSMakeRange(6, 2)]];
//        [dateStr appendString:@" "];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(9, 2)]];
        [dateStr appendString:@":"];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(11, 2)]];
        [dateStr appendString:@":"];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(13, 2)]];
        
        return dateStr.copy;
    } else {
        return dateString;
    }
}
- (NSString *)translateSecond:(int)msecond {
    
    //NSString *dateString = [NSString stringWithFormat:@"%s", date.c_str()];
//    AppLogDebug(AppLogTagAPP, @"video duration: %d", msecond); // 123444
    int second = (int) msecond/1000;
    // translate to 00:22:00
    int s = (int) second %60;
    int m = (int) second / 60;
    int h = (int) second / 3600;
    
    NSString *dateString = [NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
    return dateString;
}

@end
