//
//  ICatchFilesCollectionCell.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/13.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFilesCollectionCell.h"
#import "MPBCommonHeader.h"

@interface ICatchFilesCollectionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImgView;

@end

@implementation ICatchFilesCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    self.thumbnailImgView.backgroundColor = [UIColor orangeColor];
    self.selectedImgView.backgroundColor = RGB_HEX(0xF2F2F2, 1.0);
    self.thumbnailImgView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)setThumbnail:(UIImage *)thumbnail {
    _thumbnail = thumbnail;
    
    self.thumbnailImgView.image = thumbnail;
}

- (void)setEditState:(BOOL)editState {
    _selectedImgView.hidden = !editState;
}

- (void)setFileInfo:(ICatchFileInfo *)fileInfo {
    _selectedImgView.image = fileInfo.selected ? [UIImage imageNamed:@"ic_done_red_24dp"] : [UIImage imageNamed:@"ic_done_gray_24dp"];
    self.backgroundColor = fileInfo.selected ? RGB_HEX(0xDFDFDF, 1.0) : self.superview.backgroundColor;
}

@end
