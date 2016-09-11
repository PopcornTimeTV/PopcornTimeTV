#import "SYVLCPlayerViewController.h"
//#import "SYAppDelegate.h"
//#import "SQMovieViewController.h"
//#import "SQShowViewController.h"
//#import "SQMovieDetailViewController.h"
//#import "SQShowDetailViewController.h"
//#import "SQClientController.h"
//#import "SYContentController.h"
//#import "SYLoadingProgressView.h"
#import "SQTabMenuCollectionViewCell.h"
#import <TVVLCKit/TVVLCKit.h>
#import <TVVLCKit/VLCMediaPlayer.h>
#import "SQSubSetting.h"
#import "PopcornTime-Swift.h"
#import <PopcornTorrent/PopcornTorrent.h>
#import "SRTParser.h"
#import "UIImageView+Network.h"
#import "VLCIRTVTapGestureRecognizer.h"
#import "VLCSiriRemoteGestureRecognizer.h"
#import <MediaAccessibility/MediaAccessibility.h>

typedef NS_ENUM(NSInteger, VLCPlayerScanState)
{
    VLCPlayerScanStateNone,
    VLCPlayerScanStateForward2,
    VLCPlayerScanStateForward4,
};

static NSString *const kIndex = @"kIndex";
static NSString *const kStart = @"kStart";
static NSString *const kEnd = @"kEnd";
static NSString *const kText = @"kText";

@interface SYVLCPlayerViewController () <VLCMediaPlayerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, SQTabMenuCollectionViewCellDelegate, UIGestureRecognizerDelegate> {
    
    VLCMediaPlayer *_mediaplayer;
    NSURL *_url;
    NSString *_hash;
    NSArray *_cahcedSubtitles;
    
    BOOL _didParsed;
    NSMutableArray *_audioTracks;
    NSMutableArray *_subsTracks;
    BOOL _videoDidOpened;
    
    NSUInteger _tryAccount;
    NSArray *_subsTrackIndexes;
    NSDictionary *_currentSubParsed;
    NSArray *_currentSelectedSub;
    
    NSTimer *_subtitleTimer;
    float _sizeFloat;
    float _offsetFloat;
    CGFloat _lastPointDelayPanX;
    
    NSIndexPath *_lastIndexPathSubtitle;
    NSIndexPath *_lastIndexPathAudio;
    
    NSUInteger _lastButtonSelectedTag;
    BOOL selectActivated;
    
    SQSubSetting *subSetting;
    
    NSDictionary *_videoInfo;
    NSString *_magnet;
    NSURL* _filePath;
    
    BOOL _videoLoaded;
    
    NSTimeInterval onceToken;
}
@property (nonatomic) NSTimer *hidePlaybackControlsViewAfterDeleayTimer;
@property (nonatomic) VLCPlayerScanState scanState;
@property (nonatomic) NSNumber *scanSavedPlaybackRate;
@property (nonatomic) NSSet<UIGestureRecognizer *> *simultaneousGestureRecognizers;
@end


@implementation SYVLCPlayerViewController

#define kAlphaFocused 1.0
#define kAlphaNotFocused 0.25
#define kAlphaFocusedBackground 0.5
#define kAlphaNotFocusedBackground 0.15

- (id)initWithVideoInfo:(NSDictionary *)videoInfo {
    self = [super init];
    
    if (self) {
        _lastButtonSelectedTag = 1;
        _videoDidOpened = NO;
        self.currentSubTitleDelay = .0;
        _tryAccount = 0;
        _sizeFloat = 68.0;
        
        // Settings object
        subSetting = [SQSubSetting loadFromDisk];
        
        _videoInfo = videoInfo;
        _magnet = _videoInfo[@"magnet"];
        _videoLoaded = NO;
        _filePath=[[NSURL alloc]initWithString:@""];
        onceToken = [[NSDate date] timeIntervalSince1970];
        
        [self beginStreamingTorrent];
    }
    
    return self;
}

- (id) initWithURL:(NSURL *) url imdbID:(NSString *) hash subtitles:(NSArray *)cahcedSubtitles
{
    self = [super init];
    
    if (self) {
        _lastButtonSelectedTag = 1;
        _url = url;
        _videoDidOpened = NO;
        _hash = hash;
        _cahcedSubtitles = cahcedSubtitles;
        self.currentSubTitleDelay = .0;
        _tryAccount = 0;
        _sizeFloat = 68.0;
        _filePath=[[NSURL alloc]initWithString:@""];
        onceToken = [[NSDate date] timeIntervalSince1970];
        // Settings object
        subSetting = [SQSubSetting loadFromDisk];
    }
    
    return self;
    
}// initWithURL:

-(NSString*) downloadTorrent:(NSString*) torrent{
    // 1
    NSURL *url = [NSURL URLWithString:torrent];
    
    // 2
    NSURL* downloadPath = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
    BOOL isDir=true;
    NSError* err;
    if(![[NSFileManager defaultManager]fileExistsAtPath:[downloadPath URLByAppendingPathComponent:@"Downloads"].relativePath isDirectory:&isDir]){
        [[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath URLByAppendingPathComponent:@"Downloads"].relativePath withIntermediateDirectories:YES attributes:nil error:&err];
        if(err!=nil){
            NSLog(@"error while creating folder %@",err.description);
            return nil;
        }
    }
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    downloadPath = [downloadPath URLByAppendingPathComponent:@"Downloads"];
    downloadPath = [downloadPath URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.torrent",[_videoInfo[@"movieName"] stringByReplacingOccurrencesOfString:@" " withString:@""]]];
    downloadPath = [NSURL fileURLWithPath:[[NSString stringWithString:downloadPath.relativePath] stringByReplacingOccurrencesOfString:@":" withString:@""]];
    if([[NSFileManager defaultManager]fileExistsAtPath:downloadPath.relativePath])return [downloadPath relativePath];
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession]
                                          downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                              NSError *erro;
                                              [[NSFileManager defaultManager] moveItemAtURL:location toURL:downloadPath error:&erro];
                                              if(erro!=nil)NSLog(@"error while moving file%@",erro.description);
                                              dispatch_semaphore_signal(sem);
                                          }];
    
    // 3
    [downloadTask resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return [downloadPath relativePath];
}

- (void)beginStreamingTorrent {
    // lets not get a retain cycle going
    __weak __typeof__(self) weakSelf = self;
    selectActivated=NO;
    if([_magnet containsString:@"https://"])_magnet=[self downloadTorrent:_magnet];
    [[PTTorrentStreamer sharedStreamer] startStreamingFromFileOrMagnetLink:_magnet progress:^(PTTorrentStatus status) {
        
        // Percentage
        _percentLabel.text = [NSString stringWithFormat:@"%.0f%%", status.bufferingProgress * 100];
        
        // Status
        NSString *speedString = [NSByteCountFormatter stringFromByteCount:status.downloadSpeed countStyle:NSByteCountFormatterCountStyleBinary];
        _statsLabel.text = [NSString stringWithFormat:@"Overall Progress: %.0f%%  Speed: %@/s  Seeds: %d  Peers: %d", status.totalProgreess * 100, speedString, status.seeds, status.peers];
        //        NSLog(@"%.0f%%, %.0f%%, %@/s, %d,- %d", status.bufferingProgress*100, status.totalProgreess*100, speedString, status.seeds, status.peers);
        
        // State
        self.transportBar.bufferEndFraction=status.totalProgreess;
        _progressView.progress = status.bufferingProgress;
        if (_progressView.progress > 0.0) {
            _nameLabel.text=[_nameLabel.text stringByReplacingOccurrencesOfString:@"Processing" withString:@"Buffering"];
        }
    } readyToPlay:^(NSURL *videoFileURL,NSURL* videoFilePath) {
        _url = videoFileURL;
        _videoLoaded = YES;
        _filePath=videoFilePath;
        [weakSelf createAudioSubsDatasource];
        [weakSelf updateLoadingRatio];
        [weakSelf loadPlayer];
    } failure:^(NSError *error) {
        // Throw up an error and dismiss the view
        [weakSelf showAlertLoadingView];
    }];
}

- (void)stopStreamingTorrent {
    [[PTTorrentStreamer sharedStreamer] cancelStreaming];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view canBecomeFocused];
    
    // Subs
    {
        UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc]init];
        collectionViewFlowLayout.itemSize = CGSizeMake(228, 390);
        collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(0, 90.0, 0, 90.0);
        collectionViewFlowLayout.minimumInteritemSpacing = 0;
        collectionViewFlowLayout.minimumLineSpacing = 0;
        collectionViewFlowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UINib *cellNib = [UINib nibWithNibName:@"SQTabMenuCollectionViewCell" bundle:nil];
        [self.subTabBarCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"TabMenuCollectionViewCell"];
        [self.subTabBarCollectionView setCollectionViewLayout:collectionViewFlowLayout];
        [self.subTabBarCollectionView setContentInset:UIEdgeInsetsMake(.0, .0, .0, .0)];
        self.subTabBarCollectionView.remembersLastFocusedIndexPath = YES;
    }
    
    // Audio
    {
        UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc]init];
        collectionViewFlowLayout.itemSize = CGSizeMake(228, 390);
        collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(0, 90.0, 0, 90.0);
        collectionViewFlowLayout.minimumInteritemSpacing = 0;
        collectionViewFlowLayout.minimumLineSpacing = 0;
        collectionViewFlowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UINib *cellNib = [UINib nibWithNibName:@"SQTabMenuCollectionViewCell" bundle:nil];
        [self.audioTabBarCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"TabMenuCollectionViewCell"];
        [self.audioTabBarCollectionView setCollectionViewLayout:collectionViewFlowLayout];
        [self.audioTabBarCollectionView setContentInset:UIEdgeInsetsMake(.0, .0, .0, .0)];
        self.audioTabBarCollectionView.remembersLastFocusedIndexPath = YES;
    }
    
    //VLCMediaListPlayer* _listPlayer = [[VLCMediaListPlayer alloc] initWithOptions:@[[NSString stringWithFormat:@"--%@=%@", @"", @""]] andDrawable:self.containerView];
    
    _mediaplayer              = [[VLCMediaPlayer alloc] init];
    _mediaplayer.drawable     = self.containerView;
    _mediaplayer.delegate     = self;
    _mediaplayer.audio.volume = 200;
    
    self.transportBar.bufferStartFraction = 0.0;
    self.transportBar.bufferEndFraction = 1.0;
    self.transportBar.playbackEndFraction = 0.0;
    self.transportBar.scrubbingFraction = 0.0;
    self.indicatorView.hidden=YES;
    
    self.osdView.alpha = 0.0;
    
    NSMutableSet<UIGestureRecognizer *> *simultaneousGestureRecognizers = [NSMutableSet set];
    
    // Panning and Swiping
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:panGestureRecognizer];
    [simultaneousGestureRecognizers addObject:panGestureRecognizer];
    
    // Button presses
    UITapGestureRecognizer *playpauseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed)];
    playpauseGesture.allowedPressTypes = @[@(UIPressTypePlayPause)];
    [self.view addGestureRecognizer:playpauseGesture];
    
    UITapGestureRecognizer *menuTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonPressed:)];
    menuTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self.view addGestureRecognizer:menuTapGestureRecognizer];
    
    // IR only recognizer
    UITapGestureRecognizer *downArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(showInfoVCIfNotScrubbing)];
    downArrowRecognizer.allowedPressTypes = @[@(UIPressTypeDownArrow)];
    [self.view addGestureRecognizer:downArrowRecognizer];
    
    UITapGestureRecognizer *leftArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressLeft)];
    leftArrowRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    [self.view addGestureRecognizer:leftArrowRecognizer];
    
    UITapGestureRecognizer *rightArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressRight)];
    rightArrowRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    [self.view addGestureRecognizer:rightArrowRecognizer];
    
    // Siri remote arrow presses
    VLCSiriRemoteGestureRecognizer *siriArrowRecognizer = [[VLCSiriRemoteGestureRecognizer alloc] initWithTarget:self action:@selector(handleSiriRemote:)];
    siriArrowRecognizer.delegate = self;
    [self.view addGestureRecognizer:siriArrowRecognizer];
    [simultaneousGestureRecognizers addObject:siriArrowRecognizer];
    
    self.simultaneousGestureRecognizers = simultaneousGestureRecognizers;
    [_mediaplayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaplayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];
    
    if (_videoInfo) {
        _statsLabel.text = @"";
        _percentLabel.text = @"0%";
        _nameLabel.text = [NSString stringWithFormat:@"Processing %@...", _videoInfo[@"movieName"]];
        
        [_imageView loadImageFromURL:[NSURL URLWithString:_videoInfo[@"imageAddress"]] placeholderImage:nil];
        [_backgroundImageView loadImageFromURL:[NSURL URLWithString:_videoInfo[@"backgroundImageAddress"]] placeholderImage:nil];
    }
    
    if (_url) {
        [self loadPlayer];
    }
}

- (void)loadPlayer {
    [_loadingView setHidden:YES];
    
    [self showOSD];
    [self hideDelayButton];
    
    [self.view layoutIfNeeded];
    
    // Media player
    _mediaplayer.media = [VLCMedia mediaWithURL:_url];
    [[_mediaplayer media]synchronousParse];
    
    _videoTitle.text = _videoInfo[@"movieName"];
    
    [[_mediaplayer media] addOptions:@{kVLCSettingTextEncoding : subSetting.encoding}];
    [_mediaplayer performSelector:@selector(setTextRendererFontSize:) withObject:[NSNumber numberWithFloat:subSetting.sizeFloat]];
    [_mediaplayer play];
    
    NSUserDefaults *streamContinuanceDefaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.com.popcorntime.PopcornTime.StreamContinuance"];
    if([streamContinuanceDefaults objectForKey:_videoInfo[@"movieName"]]){
        [_mediaplayer pause];
        UIAlertController* continueWatchingAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *continueWatching = [UIAlertAction actionWithTitle:@"Continue Watching" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            [_mediaplayer setTime:[VLCTime timeWithNumber:[streamContinuanceDefaults objectForKey:_videoInfo[@"movieName"]]]];
            [_mediaplayer play];
        }];
        UIAlertAction *startWatching = [UIAlertAction actionWithTitle:@"Start from beginning" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            [_mediaplayer play];
        }];
        [continueWatchingAlert addAction:continueWatching];
        [continueWatchingAlert addAction:startWatching];
        [self presentViewController:continueWatchingAlert animated:YES completion:nil];
        [_mediaplayer pause];
    }
    
    self.subsButton.enabled      = NO;
    self.subsDelayButton.enabled = NO;
    self.audioButton.enabled     = NO;
}


- (void) dealloc
{
    NSLog(@"dealloc SYVLCPlayerController");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingRatio) object:nil];
}


- (void) updateLoadingRatio
{
    
}


- (void) showAlertLoadingView
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                                   message:NSLocalizedString(@"Could not load this video", @"Could not load this video")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Accept", @"Accept")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             if(_mediaplayer.position<1.0){
                                                                 NSUserDefaults *streamContinuanceDefaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.com.popcorntime.PopcornTime.StreamContinuance"];
                                                                 [streamContinuanceDefaults setObject:_mediaplayer.time.value forKey:_videoInfo[@"movieName"]];
                                                             }
                                                             [_mediaplayer stop];
                                                             [_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
                                                             [_mediaplayer removeObserver:self forKeyPath:@"time"];
                                                             _mediaplayer.delegate = nil;
                                                             _mediaplayer = nil;
                                                             
                                                             [self stopStreamingTorrent];
                                                             [self.navigationController popViewControllerAnimated:YES];
                                                         }];
    [alert addAction:acceptAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - New Gesture recognizer implementation
#pragma mark - UIActions
- (void)playPausePressed
{
    [self showPlaybackControlsIfNeededForUserInteraction];
    
    [self setScanState:VLCPlayerScanStateNone];
    
    if (self.transportBar.scrubbing) {
        [self selectButtonPressed];
    } else {
        [self playandPause:nil];
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            return;
        default:
            break;
    }
    
    VLCTransportBar *bar = self.transportBar;
    
    UIView *view = self.view;
    CGPoint translation = [panGestureRecognizer translationInView:view];
    
    if (!bar.scrubbing) {
        if (ABS(translation.x) > 150.0 && (selectActivated || !_mediaplayer.isPlaying)) {
            if (self.isSeekable) {
                [self startScrubbing];
                selectActivated=NO;
            }else{
                return;
            }
        } else if (translation.y > 200.0) {
            panGestureRecognizer.enabled = NO;
            panGestureRecognizer.enabled = YES;
            [self showInfoVCIfNotScrubbing];
            return;
        } else if(ABS(translation.x) > 150.0 && self.subValueDelayButton.isFocused){
            _offsetFloat += ((translation.x - _lastPointDelayPanX) * 0.005);
            NSString *signStr = (_offsetFloat > 0) ? @"+" : @"";
            NSString *delayValue = [NSString stringWithFormat:@"%@%4.2f", signStr, (roundf(_offsetFloat) * 5.0) / 10.0];
            [self.subValueDelayButton setTitle:delayValue forState:UIControlStateNormal];
            _lastPointDelayPanX = translation.x;
            [_mediaplayer setCurrentVideoSubTitleDelay:_offsetFloat];
            return;
        }else{
            return;
        }
    }
    
    [self showPlaybackControlsIfNeededForUserInteraction];
    [self setScanState:VLCPlayerScanStateNone];
    
    
    const CGFloat scaleFactor = 8.0;
    CGFloat fractionInView = translation.x/CGRectGetWidth(view.bounds)/scaleFactor;
    
    CGFloat scrubbingFraction = MAX(0.0, MIN(bar.scrubbingFraction + fractionInView,1.0));
    
    
    if (ABS(scrubbingFraction - bar.playbackEndFraction)<0.005) {
        scrubbingFraction = bar.playbackEndFraction;
    } else {
        translation.x = 0.0;
        [panGestureRecognizer setTranslation:translation inView:view];
    }
    int scrubbingTimeInt = MAX(1,_mediaplayer.media.length.intValue*scrubbingFraction);
    VLCTime *scrubbingTime = [VLCTime timeWithInt:scrubbingTimeInt];
    VLCTime *remainingTime = [VLCTime timeWithInt:-(int)(_mediaplayer.media.length.intValue-scrubbingTime.intValue)];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         //this function is called in here in order not to hinder the appearance of the scrubbing marker making it look laggy!
                         [self saveScreenshotOnTime: scrubbingTime.value withRemainingTime:remainingTime.value completion:^(UIImage * _Nullable image) {
                             //we do this cause we want to show the image immediately after we have it!
                             //dispatch_sync(dispatch_get_main_queue(), ^{
                                 bar.screenshot = image;
                             //});
                             
                         }];
                         bar.scrubbingFraction = scrubbingFraction;
                     }
                     completion:nil];
    
    [self updateTimeLabelsForScrubbingFraction:scrubbingFraction];
    
}

- (void)selectButtonPressed
{
    [self showPlaybackControlsIfNeededForUserInteraction];
    [self setScanState:VLCPlayerScanStateNone];
    
    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        bar.playbackEndFraction = bar.scrubbingFraction;
        [self stopScrubbing];
        [_mediaplayer setPosition:bar.scrubbingFraction];
    } else if(_mediaplayer.playing && ![self isTopMenuOnScreen]) {
        [_mediaplayer pause];
        selectActivated=YES;
    }else if(!_mediaplayer.playing && ![self isTopMenuOnScreen]){
        [self playandPause:nil];
    }
}
- (void)menuButtonPressed:(UITapGestureRecognizer *)recognizer
{
    
    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        [UIView animateWithDuration:0.3 animations:^{
            bar.scrubbingFraction = bar.playbackEndFraction;
            [bar layoutIfNeeded];
        }];
        [self updateTimeLabelsForScrubbingFraction:bar.playbackEndFraction];
        [self stopScrubbing];
        [self hidePlaybackControlsIfNeededAfterDelay];
    }else if([self isTopMenuOnScreen]){
        [self closeTopMenu];
    }else{
        [self done:recognizer];
    }
}

- (void)showInfoVCIfNotScrubbing
{
    if (self.transportBar.scrubbing) {
        return;
    }
    
    // prevent repeated presentation when users repeatedly and quickly press the arrow button
    if ([self isTopMenuOnScreen]) {
        return;
    }
    [self openTopMenu];
    [self animatePlaybackControlsToVisibility:NO];
}

- (void)handleIRPressLeft
{
    [self showPlaybackControlsIfNeededForUserInteraction];
    
    if (!self.isSeekable) {
        return;
    }
    
    BOOL paused = !_mediaplayer.isPlaying;
    if (paused) {
        [self jumpBackward];
    } else if(![self isTopMenuOnScreen])
    {
        [self scanForwardPrevious];
    }
}

- (void)handleIRPressRight
{
    [self showPlaybackControlsIfNeededForUserInteraction];
    
    if (!self.isSeekable) {
        return;
    }
    
    BOOL paused = !_mediaplayer.isPlaying;
    if (paused) {
        [self jumpForward];
    } else if(![self isTopMenuOnScreen]){
        [self scanForwardNext];
    }
}

- (void)handleSiriRemote:(VLCSiriRemoteGestureRecognizer *)recognizer
{
    [self showPlaybackControlsIfNeededForUserInteraction];
    
    VLCTransportBarHint hint = self.transportBar.hint;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            if (recognizer.isLongPress) {
                if (!self.isSeekable && recognizer.touchLocation == VLCSiriRemoteTouchLocationRight) {
                    [self setScanState:VLCPlayerScanStateForward2];
                    return;
                }
            } else {
                switch (recognizer.touchLocation) {
                    case VLCSiriRemoteTouchLocationLeft:
                        hint = VLCTransportBarHintJumpBackward10;
                        break;
                    case VLCSiriRemoteTouchLocationRight:
                        hint = VLCTransportBarHintJumpForward10;
                        break;
                    default:
                        hint = VLCTransportBarHintNone;
                        break;
                }
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (recognizer.isClick && !recognizer.isLongPress) {
                [self handleSiriPressUpAtLocation:recognizer.touchLocation];
            }
            [self setScanState:VLCPlayerScanStateNone];
            break;
        case UIGestureRecognizerStateCancelled:
            hint = VLCTransportBarHintNone;
            [self setScanState:VLCPlayerScanStateNone];
            break;
        default:
            break;
    }
    self.transportBar.hint = self.isSeekable ? hint : VLCPlayerScanStateNone;
}

- (void)handleSiriPressUpAtLocation:(VLCSiriRemoteTouchLocation)location
{
    switch (location) {
        case VLCSiriRemoteTouchLocationLeft:
            if (self.isSeekable) {
                [self jumpBackward];
            }
            break;
        case VLCSiriRemoteTouchLocationRight:
            if (self.isSeekable) {
                [self jumpForward];
            }
            break;
        default:
            [self selectButtonPressed];
            break;
    }
}

#pragma mark -
static const NSInteger VLCJumpInterval = 10000; // 10 seconds
- (void)jumpForward
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    if (_mediaplayer.isPlaying) {
        [self jumpInterval:VLCJumpInterval];
    } else {
        [self scrubbingJumpInterval:VLCJumpInterval];
    }
}
- (void)jumpBackward
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    if (_mediaplayer.isPlaying) {
        [self jumpInterval:-VLCJumpInterval];
    } else {
        [self scrubbingJumpInterval:-VLCJumpInterval];
    }
}

- (void)jumpInterval:(NSInteger)interval
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    NSInteger duration = _mediaplayer.media.length.intValue;
    if (duration==0) {
        return;
    }
    
    CGFloat intervalFraction = ((CGFloat)interval)/((CGFloat)duration);
    CGFloat currentFraction = _mediaplayer.position;
    currentFraction += intervalFraction;
    _mediaplayer.position = currentFraction;
}

- (void)scrubbingJumpInterval:(NSInteger)interval
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    NSInteger duration = _mediaplayer.media.length.intValue;
    if (duration==0) {
        return;
    }
    CGFloat intervalFraction = ((CGFloat)interval)/((CGFloat)duration);
    VLCTransportBar *bar = self.transportBar;
    bar.scrubbing = YES;
    CGFloat currentFraction = bar.scrubbingFraction;
    currentFraction += intervalFraction;
    bar.scrubbingFraction = currentFraction;
    [self updateTimeLabelsForScrubbingFraction:currentFraction];
}

- (void)scanForwardNext
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    VLCPlayerScanState nextState = self.scanState;
    switch (self.scanState) {
        case VLCPlayerScanStateNone:
            nextState = VLCPlayerScanStateForward2;
            break;
        case VLCPlayerScanStateForward2:
            nextState = VLCPlayerScanStateForward4;
            break;
        case VLCPlayerScanStateForward4:
            return;
        default:
            return;
    }
    [self setScanState:nextState];
}

- (void)scanForwardPrevious
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    VLCPlayerScanState nextState = self.scanState;
    switch (self.scanState) {
        case VLCPlayerScanStateNone:
            return;
        case VLCPlayerScanStateForward2:
            nextState = VLCPlayerScanStateNone;
            break;
        case VLCPlayerScanStateForward4:
            nextState = VLCPlayerScanStateForward2;
            break;
        default:
            return;
    }
    [self setScanState:nextState];
}

- (void)setScanState:(VLCPlayerScanState)scanState
{
    if (_scanState == scanState) {
        return;
    }
    
    NSAssert(self.isSeekable || scanState == VLCPlayerScanStateNone, @"Tried to seek while media not seekable.");
    
    if (_scanState == VLCPlayerScanStateNone) {
        self.scanSavedPlaybackRate = @(_mediaplayer.rate);
    }
    _scanState = scanState;
    float rate = 1.0;
    VLCTransportBarHint hint = VLCTransportBarHintNone;
    switch (scanState) {
        case VLCPlayerScanStateForward2:
            rate = 2.0;
            hint = VLCTransportBarHintScanForward;
            break;
        case VLCPlayerScanStateForward4:
            rate = 4.0;
            hint = VLCTransportBarHintScanForward;
            break;
            
        case VLCPlayerScanStateNone:
        default:
            rate = self.scanSavedPlaybackRate.floatValue ?: 1.0;
            hint = VLCTransportBarHintNone;
            self.scanSavedPlaybackRate = nil;
            break;
    }
    
    _mediaplayer.rate = rate;
    [self.transportBar setHint:hint];
}


- (BOOL)isSeekable
{
    return _mediaplayer.isSeekable;
}

#pragma mark -
- (void)updateTimeLabelsForScrubbingFraction:(CGFloat)scrubbingFraction
{
    VLCTransportBar *bar = self.transportBar;
    // MAX 1, _ is ugly hack to prevent --:-- instead of 00:00
    int scrubbingTimeInt = MAX(1,_mediaplayer.media.length.intValue*scrubbingFraction);
    VLCTime *scrubbingTime = [VLCTime timeWithInt:scrubbingTimeInt];
    bar.markerTimeLabel.text = [scrubbingTime stringValue];
    VLCTime *remainingTime = [VLCTime timeWithInt:-(int)(_mediaplayer.media.length.intValue-scrubbingTime.intValue)];
    bar.remainingTimeLabel.text = [remainingTime stringValue];
}

-(void)saveScreenshotOnTime:(NSNumber*)time withRemainingTime:(NSNumber*)remainingTime completion:(void(^)(UIImage* _Nullable image))completionBlock{
    AVAssetImageGenerator* imageGen = [AVAssetImageGenerator assetImageGeneratorWithAsset:[[AVURLAsset alloc ]initWithURL:_url options:nil]];
    imageGen.appliesPreferredTrackTransform = true;
    imageGen.requestedTimeToleranceAfter= kCMTimeZero;
    imageGen.requestedTimeToleranceBefore = kCMTimeZero;
    [imageGen cancelAllCGImageGeneration];
    [imageGen generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(time.floatValue/1000.0,1000000)]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if(error==nil){
            UIImage *uiImage = [UIImage imageWithCGImage:image];
            if (completionBlock != nil) completionBlock(uiImage);
            uiImage=nil;
            return;
        }else{
            NSLog(@"could not retrieve screenshot, error:%@",error.description);
            completionBlock(nil);
            return;
        }
    }];

}

- (void)startScrubbing
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");
    
    self.transportBar.scrubbing = YES;
    if (_mediaplayer.isPlaying) {
        [self playandPause:nil];
    }
}
- (void)stopScrubbing
{
    self.transportBar.scrubbing = NO;
    [_mediaplayer play];
}

- (void)updateActivityIndicatorForState:(VLCMediaPlayerState)state {
    UIActivityIndicatorView *indicator = self.indicatorView;
    switch (state) {
        case VLCMediaPlayerStateBuffering:
            if (!indicator.isAnimating) {
                indicator.hidden = NO;
                [indicator startAnimating];
            }
            break;
        default:
            if (indicator.isAnimating) {
                [indicator stopAnimating];
                indicator.hidden = YES;
            }
            break;
    }
}


#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.allowedPressTypes containsObject:@(UIPressTypeMenu)]) {
        return self.transportBar.scrubbing;
    }
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [self.simultaneousGestureRecognizers containsObject:gestureRecognizer];
}

- (void)playbackPositionUpdated
{
    // FIXME: hard coded state since the state in mediaPlayer is incorrectly still buffering
    [self updateActivityIndicatorForState:VLCMediaPlayerStatePlaying];
    
    if (self.osdView.alpha != 0.0) {
        [self updateTransportBarPosition];
    }
}

- (void)updateTransportBarPosition
{
    VLCMediaPlayer *mediaPlayer = _mediaplayer;
    VLCTransportBar *transportBar = self.transportBar;
    transportBar.remainingTimeLabel.text = [[mediaPlayer remainingTime] stringValue];
    transportBar.markerTimeLabel.text = [[mediaPlayer time] stringValue];
    transportBar.playbackEndFraction = mediaPlayer.position;
}

#pragma mark - PlaybackControls

- (void)fireHidePlaybackControlsIfNotPlayingTimer:(NSTimer *)timer
{
    BOOL playing = [_mediaplayer isPlaying];
    if (playing) {
        [self animatePlaybackControlsToVisibility:NO];
        
    }
}
- (void)showPlaybackControlsIfNeededForUserInteraction
{
    if (self.osdView.alpha == 0.0) {
        [self animatePlaybackControlsToVisibility:YES];
        // We need an additional update here because in some cases (e.g. when the playback was
        // paused or started buffering), the transport bar is only updated when it is visible
        // and if the playback is interrupted, no updates of the transport bar are triggered.
        [self updateTransportBarPosition];
    }
    [self hidePlaybackControlsIfNeededAfterDelay];
}
- (void)hidePlaybackControlsIfNeededAfterDelay
{
    self.hidePlaybackControlsViewAfterDeleayTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                                     target:self
                                                                                   selector:@selector(fireHidePlaybackControlsIfNotPlayingTimer:)
                                                                                   userInfo:nil repeats:NO];
}


- (void)animatePlaybackControlsToVisibility:(BOOL)visible
{
    NSTimeInterval duration = visible ? 0.3 : 1.0;
    
    CGFloat alpha = visible ? 1.0 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^{
                         self.osdView.alpha = alpha;
                     }];
}


#pragma mark - Properties
- (void)setHidePlaybackControlsViewAfterDeleayTimer:(NSTimer *)hidePlaybackControlsViewAfterDeleayTimer {
    [_hidePlaybackControlsViewAfterDeleayTimer invalidate];
    _hidePlaybackControlsViewAfterDeleayTimer = hidePlaybackControlsViewAfterDeleayTimer;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    [self playbackPositionUpdated];
}

#pragma mark - Change focus

- (UIView *) preferredFocusedView
{
    if (![self isTopMenuOnScreen]) {
        return self.view;
    }
    
    if ([self.subValueDelayButton isFocused]) {
        
        self.subsButton.enabled      = YES;
        self.subsDelayButton.enabled = YES;
        self.audioButton.enabled     = YES;
        
        return self.subsDelayButton;
    }
    
    if ([self.topButton isFocused]) {
        
        self.subsButton.enabled     = YES;
        self.subsDelayButton.enabled = YES;
        self.audioButton.enabled    = YES;
        
        switch (_lastButtonSelectedTag) {
            case 1:
                return self.subsButton;
                break;
            case 2:
                return self.subsDelayButton;
                break;
            default:
                return self.audioButton;
                break;
        }
    }
    
    return self.view;
    
}// preferredFocusedView


- (void) didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    
    //NSLog(@"didUpdateFocusInContext : %@", context.nextFocusedView);
    
    if ([context.nextFocusedView isKindOfClass:[UIButton class]]) {
        //NSLog(@"next: button (%li)", context.nextFocusedView.tag);
    }
    if ([context.nextFocusedView isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
        //NSLog(@"next: cell");
    }
    if ([context.previouslyFocusedView isKindOfClass:[UIButton class]]) {
        //NSLog(@"previous: button (%li)", context.previouslyFocusedView.tag);
    }
    if ([context.previouslyFocusedView isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
        //NSLog(@"previous: cell");
    }
    
    if ([context.previouslyFocusedView isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
        self.subsButton.enabled      = NO;
        self.subsDelayButton.enabled = NO;
        self.audioButton.enabled     = NO;
        
        if (![context.nextFocusedView isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
            SQTabMenuCollectionViewCell *tabCell = (SQTabMenuCollectionViewCell *) context.previouslyFocusedView;
            tabCell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:kAlphaNotFocused];
        }
    }
    
    if ([context.nextFocusedView isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
        [self activeCollectionViews];
        [self deactiveHeaderButtons];
    }
    
    BOOL nextFocusedIsHeaderButton = (context.nextFocusedView.tag > 0 && context.nextFocusedView.tag < 4);
    BOOL previousFocusedIsHeaderButton = (context.previouslyFocusedView.tag > 0 && context.previouslyFocusedView.tag < 4);
    
    if (nextFocusedIsHeaderButton) {
        _lastButtonSelectedTag = context.nextFocusedView.tag;
        
        self.subTabBarCollectionView.hidden   = (_lastButtonSelectedTag != 1);
        self.subValueDelayButton.hidden       = (_lastButtonSelectedTag != 2);
        self.audioTabBarCollectionView.hidden = (_lastButtonSelectedTag != 3);
        
        if (!previousFocusedIsHeaderButton) {
            [self deactiveCollectionViews];
            [self activeHeaderButtons];
        }
        else {
            [self deactiveHeaderButtons];
        }
    } else if (context.nextFocusedView.tag == 1001) {
        if ([context.previouslyFocusedView isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
            [self deactiveCollectionViews];
            [self setNeedsFocusUpdate];
        } else {
            [self closeTopMenu];
            //            NSLog(@"Update Focus");
        }
    }
    
    if (context.nextFocusedView.tag == 4) {
        [self deactiveHeaderButtons];
        [self.subValueDelayButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:kAlphaFocused] forState:UIControlStateFocused];
    } else if (context.previouslyFocusedView.tag == 4) {
        //        self.middleButton.hidden = YES;
        [self activeHeaderButtons];
        [self.subValueDelayButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:kAlphaFocusedBackground] forState:UIControlStateFocused];
    }
    
}


- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
    return YES;
}


#pragma mark - Top Menu

- (void) openTopMenu
{
    [self hideOSD];
    self.subsButton.enabled      = NO;
    self.subsDelayButton.enabled = NO;
    self.audioButton.enabled     = NO;
    
    self.topTopMenuSpace.constant = .0;
    
    _topMenuContainerView.hidden = NO;
    _topButton.hidden            = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self setNeedsFocusUpdate];
    }];
}


- (void) closeTopMenu
{
    self.topTopMenuSpace.constant = -232.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        _topMenuContainerView.hidden = YES;
        _topButton.hidden            = YES;
        [self setNeedsFocusUpdate];
        [self performSelector:@selector(hideOSD) withObject:nil afterDelay:4.0];
    }];
}


- (BOOL) isTopMenuOnScreen
{
    return (!_topMenuContainerView.hidden);
}

#pragma mark - Actions

- (IBAction)playandPause:(id)sender
{
    [self showOSD];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideOSD) object:nil];
    
    if (_mediaplayer.isPlaying) {
        [_mediaplayer pause];
        return;
    }
    [self performSelector:@selector(hideOSD) withObject:nil afterDelay:4.0];
    [_mediaplayer play];
    
}


- (IBAction)done:(id)sender
{
    if (!self.topMenuContainerView.hidden) {
        [self closeTopMenu];
        return;
    }
    
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *) sender;
        
        if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            
            // Si hay entrado realmente en el video
            // guarda el ratio
            if (_videoDidOpened) {
                //            if (_videoDidOpened && _hash.length > 0) {
                
                //                float ratio = [self currentTimeAsPercentage];
                //                if (ratio > 0.95) {
                //                    ratio = 1.0;
                //                }
                
                NSArray *viewControllers = [self.navigationController viewControllers];
                
                for (NSInteger i = [viewControllers count]-1 ; i >= 0 ; i--) {
                    
                    //                    id object = viewControllers[i];
                    
                    /*
                     if ([object isKindOfClass:[SQMovieDetailViewController class]]) {
                     SQMovieDetailViewController *detailViewController = (SQMovieDetailViewController *) object;
                     [[SYContentController shareController]setRatio:ratio toMovie:detailViewController.imdb];
                     break;
                     }
                     else if ([object isKindOfClass:[SQShowDetailViewController class]]) {
                     SQShowDetailViewController *detailViewController = (SQShowDetailViewController *) object;
                     [[SYContentController shareController]setRatio:ratio
                     toEpisode:detailViewController.episodeSelected
                     withBlock:^(NSData *data, NSError *error) {
                     [detailViewController setRatio:ratio];
                     }];
                     break;
                     }
                     */
                }
                
                [self rememberAudioSub];
                
            }
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingRatio) object:nil];
            
            if(_mediaplayer.position<1.0){
                NSUserDefaults *streamContinuanceDefaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.com.popcorntime.PopcornTime.StreamContinuance"];
                [streamContinuanceDefaults setObject:_mediaplayer.time.value forKey:_videoInfo[@"movieName"]];
            }
            [_mediaplayer stop];
            [_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
            [_mediaplayer removeObserver:self forKeyPath:@"time"];
            _mediaplayer.delegate = nil;
            _mediaplayer = nil;
            
            
            //            [[SQClientController shareClient]stopStreamingWithHash:_hash withBlock:nil];
            
            [self stopStreamingTorrent];
            
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (!sender || [sender isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *) sender;
        
        if (!sender || panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            /*
             if (_hash.length > 0) {
             float ratio = 1.0;
             
             NSArray *viewControllers = [[self.rootViewController navigationController]viewControllers];
             
             for (NSInteger i = [viewControllers count]-1 ; i >= 0 ; i--) {
             
             id object = viewControllers[i];
             
             if ([object isKindOfClass:[SQMovieDetailViewController class]]) {
             SQMovieDetailViewController *detailViewController = (SQMovieDetailViewController *) object;
             [[SYContentController shareController]setRatio:ratio toMovie:detailViewController.imdb];
             break;
             }
             else if ([object isKindOfClass:[SQShowDetailViewController class]]) {
             SQShowDetailViewController *detailViewController = (SQShowDetailViewController *) object;
             [[SYContentController shareController]setRatio:ratio toEpisode:detailViewController.episodeSelected withBlock:^(NSData *data, NSError *error) {
             [self.rootViewController setRatio:ratio];
             }];
             
             break;
             }
             }
             
             [self rememberAudioSub];
             }
             */
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingRatio) object:nil];
            if(_mediaplayer.position<1.0){
                NSUserDefaults *streamContinuanceDefaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.com.popcorntime.PopcornTime.StreamContinuance"];
                [streamContinuanceDefaults setObject:_mediaplayer.time.value forKey:_videoInfo[@"movieName"]];
            }
            [_mediaplayer stop];
            [_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
            [_mediaplayer removeObserver:self forKeyPath:@"time"];
            _mediaplayer.delegate = nil;
            _mediaplayer = nil;
            
            //            [[SQClientController shareClient]stopStreamingWithHash:_hash withBlock:nil];
            
            [self stopStreamingTorrent];
            
            
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
}


- (void) rememberAudioSub
{
    Subtitle *subSelected = _subsTracks[_lastIndexPathSubtitle.row];
    //NSDictionary *audioSelected = _audioTracks[_lastIndexPathAudio.row];
    //NSLog(@"audio : %@", audioSelected);
    
    NSString *currentSubs = [[subSelected language] lowercaseString];
    if (currentSubs) {
        [[NSUserDefaults standardUserDefaults] setValue:currentSubs forKey:@"currentSubs"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


#pragma mark - VLC Delegate

- (void) mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayer *player = [aNotification object];
    //NSLog(@"mediaPlayerStateChanged");
    
    if(player.state==VLCMediaPlayerStatePlaying && self.presentedViewController!=nil)[player pause];
    
    if(player.state== VLCMediaPlayerStateStopped) {
        //NSLog(@"VLCMediaPlayerStateStopped");
        [self done:nil];
        return;
    }
    [self updateActivityIndicatorForState:player.state];
    
    
}// mediaPlayerStateChanged:


- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification
{
    self.indicatorView.hidden = YES;
    if(!self.indicatorView.isAnimating)[self.indicatorView startAnimating];
    
    if (!_videoDidOpened) {
        
        self.osdView.alpha = .0;
        
        self.osdView.hidden = NO;
        
        [self showOSD];
        
        if (_initialRatio != 0) {
            [_mediaplayer setPosition:_initialRatio];
        }
        [self createAudioSubsDatasource];
        [self performSelector:@selector(hideOSD) withObject:nil afterDelay:5.0];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLoadingRatio) object:nil];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.loadingLogo.alpha = .0;
            if(self.indicatorView.isAnimating)[self.indicatorView stopAnimating];
            self.indicatorView.hidden = NO;
        }];
        
        _videoDidOpened = YES;
    }
    
    self.indicatorView.hidden = YES;
    
    
    
}


#pragma mark - OSD

- (void) showOSD
{
    
    [UIView animateWithDuration:0.4 animations:^{
        self.osdView.alpha = 1.0;
        [self.view layoutIfNeeded];
    }];
}


- (void) hideOSD
{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideOSD) object:nil];
    [UIView animateWithDuration:0.4 animations:^{
        self.osdView.alpha = .0;
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished) {
    }];
}


- (BOOL) isOSDOnScreen
{
    return (self.osdView.alpha == 1.0);
}


#pragma mark - Active/Deactive CollectionViews

- (void) activeCollectionViews
{
    for (SQTabMenuCollectionViewCell *cell in [self.subTabBarCollectionView visibleCells]) {
        NSIndexPath *indexPath = [self.subTabBarCollectionView indexPathForCell:cell];
        float alpha = (indexPath.row == _lastIndexPathSubtitle.row) ? kAlphaFocused : kAlphaNotFocused;
        cell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    }
    
    for (SQTabMenuCollectionViewCell *cell in [self.audioTabBarCollectionView visibleCells]) {
        NSIndexPath *indexPath = [self.audioTabBarCollectionView indexPathForCell:cell];
        float alpha = (indexPath.row == _lastIndexPathAudio.row) ? kAlphaFocused : kAlphaNotFocused;
        cell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    }
}


- (void) deactiveCollectionViews
{
    for (SQTabMenuCollectionViewCell *cell in [self.subTabBarCollectionView visibleCells]) {
        NSIndexPath *indexPath = [self.subTabBarCollectionView indexPathForCell:cell];
        float alpha = (indexPath.row == _lastIndexPathSubtitle.row) ? kAlphaFocusedBackground : kAlphaNotFocusedBackground;
        cell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    }
    
    for (SQTabMenuCollectionViewCell *cell in [self.audioTabBarCollectionView visibleCells]) {
        NSIndexPath *indexPath = [self.audioTabBarCollectionView indexPathForCell:cell];
        float alpha = (indexPath.row == _lastIndexPathAudio.row) ? kAlphaFocusedBackground : kAlphaNotFocusedBackground;
        cell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    }
}


- (void) activeHeaderButtons
{
    UIColor *selectedColor = [UIColor colorWithWhite:1.0 alpha:kAlphaFocused];
    UIColor *unSelectedColor = [UIColor colorWithWhite:1.0 alpha:kAlphaNotFocused];
    
    [self.subsButton setTitleColor:(self.subTabBarCollectionView.hidden) ? unSelectedColor : selectedColor
                          forState:UIControlStateNormal];
    [self.subsDelayButton setTitleColor:(self.subValueDelayButton.hidden) ? unSelectedColor : selectedColor
                               forState:UIControlStateNormal];
    [self.audioButton setTitleColor:(self.audioTabBarCollectionView.hidden) ? unSelectedColor : selectedColor
                           forState:UIControlStateNormal];
    
}


- (void) deactiveHeaderButtons
{
    UIColor *selectedColor = [UIColor colorWithWhite:1.0 alpha:kAlphaFocusedBackground];
    UIColor *unSelectedColor = [UIColor colorWithWhite:1.0 alpha:kAlphaNotFocusedBackground];
    
    [self.subsButton setTitleColor:(self.subTabBarCollectionView.hidden) ? unSelectedColor : selectedColor
                          forState:UIControlStateNormal];
    [self.subsDelayButton setTitleColor:(self.subValueDelayButton.hidden) ? unSelectedColor : selectedColor
                               forState:UIControlStateNormal];
    [self.audioButton setTitleColor:(self.audioTabBarCollectionView.hidden) ? unSelectedColor : selectedColor
                           forState:UIControlStateNormal];
    
}


#pragma mark - UICollectionView Data Source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([collectionView isEqual:self.subTabBarCollectionView]) {
        return [_subsTracks count];
    }
    else {
        return [_audioTracks count];
    }
    
}// collectionView:numberOfItemsInSection:


- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"TabMenuCollectionViewCell";
    
    SQTabMenuCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.delegate = self;
    if ([collectionView isEqual:self.subTabBarCollectionView]) {
        Subtitle *item = [_subsTracks objectAtIndex:indexPath.row];
        cell.nameLabel.text = item.language;
    } else {
        NSDictionary *item = [_audioTracks objectAtIndex:indexPath.row];
        cell.nameLabel.text = item[@"name"];
    }
    
    if ([collectionView isEqual:self.subTabBarCollectionView]) {
        cell.collectionViewType = SQTabMenuCollectionViewTypeSubtitle;
        float alpha = (indexPath.row == _lastIndexPathSubtitle.row) ? kAlphaFocusedBackground : kAlphaNotFocusedBackground;
        cell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    } else {
        cell.collectionViewType = SQTabMenuCollectionViewTypeAudio;
        float alpha = (indexPath.row == _lastIndexPathSubtitle.row) ? kAlphaFocusedBackground : kAlphaNotFocusedBackground;
        cell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    }
    
    return cell;
    
}// collectionView:cellForItemAtIndexPath


- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.subTabBarCollectionView]) {
        [self newSubSelected];
        [self closeTopMenu];
    } else if ([collectionView isEqual:self.audioTabBarCollectionView]) {
        [self newAudioSelected];
        [self closeTopMenu];
    }
    
}// collectionView:didSelectItemAtIndexPath:


#pragma mark - Select Items

- (void) newItemSelected:(id) cell
{
    
    if ([cell isKindOfClass:[SQTabMenuCollectionViewCell class]]) {
        SQTabMenuCollectionViewCell *tabCell = (SQTabMenuCollectionViewCell *) cell;
        
        // Sub
        if (tabCell.collectionViewType == SQTabMenuCollectionViewTypeSubtitle) {
            if (_lastIndexPathSubtitle) {
                SQTabMenuCollectionViewCell *lastCell = (SQTabMenuCollectionViewCell *)[_subTabBarCollectionView cellForItemAtIndexPath:_lastIndexPathSubtitle];
                lastCell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:kAlphaNotFocusedBackground];
            }
            
            tabCell.nameLabel.textColor = [UIColor whiteColor];
            _lastIndexPathSubtitle = [self.subTabBarCollectionView indexPathForCell:tabCell];
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(newSubSelected) object:nil];
            [self performSelector:@selector(newSubSelected) withObject:nil afterDelay:2.0];
            
            if (_lastIndexPathSubtitle.row != 0) {
                [self showDelayButton];
            }
            else {
                [self hideDelayButton];
            }
        }
        
        // Audio
        if (tabCell.collectionViewType == SQTabMenuCollectionViewTypeAudio) {
            
            if (_lastIndexPathAudio) {
                SQTabMenuCollectionViewCell *lastCell = (SQTabMenuCollectionViewCell *)[_audioTabBarCollectionView cellForItemAtIndexPath:_lastIndexPathAudio];
                lastCell.nameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:kAlphaNotFocusedBackground];
            }
            
            tabCell.nameLabel.textColor = [UIColor whiteColor];
            _lastIndexPathAudio = [self.audioTabBarCollectionView indexPathForCell:tabCell];
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(newAudioSelected) object:nil];
            [self performSelector:@selector(newAudioSelected) withObject:nil afterDelay:2.0];
        }
    }
    
}// newItemSelected


- (void) restoreSub
{
    CFArrayRef subarray =  MACaptionAppearanceCopySelectedLanguages(kMACaptionAppearanceDomainDefault);
    NSString *currentSubs = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentSubs"];
    if ((!currentSubs || [currentSubs isEqual:@"off"]) && CFArrayGetCount(subarray)<=0) {
        return;
    }
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString* subname = [locale displayNameForKey:NSLocaleIdentifier value:CFArrayGetValueAtIndex(subarray, 0)].lowercaseString;
    for (Subtitle *sub in _subsTracks) {
        
        NSString *name = [[sub language] lowercaseString];
        if (currentSubs==nil){
            if ([name isEqual:subname]) {
                NSUInteger row = [_subsTracks indexOfObject:sub];
                _lastIndexPathSubtitle = [NSIndexPath indexPathForRow:row inSection:0];
                [self newSubSelected];
                return;
            }
        }else{
            if ([name isEqual:currentSubs]) {
                NSUInteger row = [_subsTracks indexOfObject:sub];
                _lastIndexPathSubtitle = [NSIndexPath indexPathForRow:row inSection:0];
                [self newSubSelected];
                return;
            }
        }
            
    }
    
}


- (void) newSubSelected
{
    Subtitle *lastSelected = _subsTracks[_lastIndexPathSubtitle.row];
    
    if (lastSelected.index) {
        [_mediaplayer setCurrentVideoSubTitleIndex:lastSelected.index.intValue];
    } else {
        [_mediaplayer setCurrentVideoSubTitleIndex:-1];
        NSString *file = lastSelected.filePath;
        if (file) {
            [_mediaplayer addPlaybackSlave:[NSURL fileURLWithPath:file] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
        } else {
            if (lastSelected.fileAddress) {
                [lastSelected downloadSubtitle:^(NSString * _Nullable filePath) {
                    [_mediaplayer addPlaybackSlave:[NSURL fileURLWithPath:filePath] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
                }];
            }
        }
    }
    
}

- (NSString *)readSubtitleAtPath:(NSString *)path withEncoding:(NSString *)encoding
{
    
    NSString *string = nil;
    NSData *data = [NSData dataWithContentsOfFile:path];
    CFStringEncoding encodingType = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encoding);
    if (encodingType != kCFStringEncodingInvalidId) {
        CFStringRef cfstring = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, data.length, encodingType, YES);
        string = (__bridge NSString *)cfstring;
        CFRelease(cfstring);
        return string;
    }
    
    // Sometimes the encoding is unknown (i.e. Catalan) so we have to fallback on some sort of other check
    [NSString stringEncodingForData:data encodingOptions:nil convertedString:&string usedLossyConversion:nil];
    if (string) {
        return string;
    }
    
    // Just as a last resort failsafe, open in UTF-8. Encoding will probably be broken but it will open.
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
    
}

- (void) newAudioSelected
{
    NSDictionary *lastSelected = _audioTracks[_lastIndexPathAudio.row];
    [_mediaplayer setCurrentAudioTrackIndex:[lastSelected[@"index"]intValue]];
    
}


- (void) showDelayButton
{
    self.middleSubsConstraint.constant = -280.0;
    self.middleAudioConstraint.constant = 280.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.subsDelayButton.alpha = 1.0;
        [self.view layoutIfNeeded];
    }];
}


- (void) hideDelayButton
{
    self.middleSubsConstraint.constant = -140.0;
    self.middleAudioConstraint.constant = 140.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.subsDelayButton.alpha = .0;
        [self.view layoutIfNeeded];
    }];
}


#pragma mark - Subtitles Datasource

- (void) createAudioSubsDatasource
{
    NSString *path = [_filePath.relativePath stringByRemovingPercentEncoding];
    [[SubtitleManager sharedManager] searchWithFile:path completion:^(NSArray<Subtitle *> * _Nullable subtitles) {
        _subsTracks = [NSMutableArray array];
        [_subsTracks addObject:[[Subtitle alloc] initWithLanguage:@"Off" fileAddress:nil fileName:nil encoding:nil]];
        [_subsTracks addObjectsFromArray:subtitles];
        
        // Subtitles Internal
        _subsTrackIndexes = [_mediaplayer videoSubTitlesIndexes];
        NSArray *subsTrackNames = nil;
        @try {
            subsTrackNames = [_mediaplayer videoSubTitlesNames];
        }
        
        @catch (NSException *exception) {
            NSMutableArray *subsTrackNamesMut = [NSMutableArray array];
            for (id item in _subsTrackIndexes) {
                NSString *subsName = [NSString stringWithFormat:@"Subtitle %lu", [_subsTrackIndexes indexOfObject:item]];
                [subsTrackNamesMut addObject:subsName];
            }
            subsTrackNames = [subsTrackNamesMut copy];
        }
        
        if ([_subsTrackIndexes count] == [subsTrackNames count] && [_subsTrackIndexes count] > 1) {
            for (NSUInteger i = 1; i < [_subsTrackIndexes count]; i++) {
                Subtitle *item = [[Subtitle alloc] initWithLanguage:[subsTrackNames objectAtIndex:i] fileAddress:nil fileName:nil encoding:nil];
                item.index = [NSNumber numberWithUnsignedInteger:i];
                [_subsTracks addObject:item];
            }
        }
        
        // Audio
        _audioTracks = [NSMutableArray array];
        NSArray *audioTrackIndexes = [_mediaplayer audioTrackIndexes];
        NSArray *audioTrackNames = nil;
        @try {
            audioTrackNames = [_mediaplayer audioTrackNames];
        }
        
        @catch (NSException *exception) {
            NSMutableArray *audioTrackNamesMut = [NSMutableArray array];
            for (id item in audioTrackIndexes) {
                NSString *audioName = [NSString stringWithFormat:@"Audio %lu", [audioTrackIndexes indexOfObject:item]];
                [audioTrackNamesMut addObject:audioName];
            }
            audioTrackNames = [audioTrackNamesMut copy];
        }
        
        if ([audioTrackIndexes count] == [audioTrackNames count] && [audioTrackIndexes count] > 1) {
            for (NSUInteger i = 1; i < [audioTrackIndexes count]; i++)
                [_audioTracks addObject:@{@"index": [audioTrackIndexes objectAtIndex:i], @"name": [audioTrackNames objectAtIndex:i]}];
        }
        else {
            [_audioTracks addObject:@{@"name" : @"Disabled"}];
        }
        
        _lastIndexPathSubtitle = [NSIndexPath indexPathForRow:0 inSection:0];
        _lastIndexPathAudio    = [NSIndexPath indexPathForRow:0 inSection:0];
        
        self.subTabBarCollectionView.dataSource = self;
        self.subTabBarCollectionView.delegate   = self;
        [self.subTabBarCollectionView reloadData];
        
        self.audioTabBarCollectionView.dataSource = self;
        self.audioTabBarCollectionView.delegate   = self;
        [self.audioTabBarCollectionView reloadData];
        
        [self restoreSub];
    }];
    
    /*
     [[SQClientController shareClient]subtitlesListForHash:_hash
     withBlock:^(NSData *data, NSError *error) {
     
     SBJsonParser *parser = [[SBJsonParser alloc]init];
     id object = [parser objectWithData:data];
     
     if (!error && [object isKindOfClass:[NSArray class]]) {
     
     
     }
     else {
     _tryAccount++;
     if (_tryAccount < 10) {
     [self performSelector:@selector(createAudioSubsDatasource)
     withObject:nil afterDelay:5.0];
     }
     }
     }];
     */
    
}// createOptionsRoll


#pragma mark - Subtitles text


- (float) currentTimeSeconds
{
    float timevlc = (float) [[_mediaplayer time]intValue];
    return timevlc * 0.001;
}



#pragma mark - Time Custom Methods

- (NSString *)durationAsString
{
    int totalDurationInSeconds = (int) ([[_mediaplayer time]intValue] - [[_mediaplayer remainingTime]intValue]) * 0.001;
    div_t hours = div(totalDurationInSeconds,3600);
    div_t minutes = div(hours.rem,60);
    int seconds = minutes.rem;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours.quot, minutes.quot, seconds];
    
}// durationAsString


- (NSString *)durationToEndAsString
{
    int totalDurationInSeconds = (int) [[_mediaplayer remainingTime]intValue] * 0.001;
    div_t hours = div(-totalDurationInSeconds,3600);
    div_t minutes = div(hours.rem,60);
    int seconds = minutes.rem;
    
    return [NSString stringWithFormat:@"-%02d:%02d:%02d", hours.quot, minutes.quot, seconds];
    
}// durationToEndAsString


- (NSString *)currentTimeAsString
{
    int actualSeconds = [[_mediaplayer time]intValue] * 0.001;
    div_t hours = div(actualSeconds,3600);
    div_t minutes = div(hours.rem,60);
    int seconds = minutes.rem;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours.quot, minutes.quot, seconds];
    
}// currentTimeAsString


- (float) currentTimeAsPercentage
{
    float currentTimeInSeconds  = (float)[[_mediaplayer time]intValue];
    float durationTimeInSeconds = currentTimeInSeconds - (float)[[_mediaplayer remainingTime]intValue];
    if (durationTimeInSeconds == 0 || isnan(durationTimeInSeconds)) {
        return 0;
    }
    
    float result = currentTimeInSeconds/durationTimeInSeconds;
    
    return result;
    
}// currentTimeAsPercentage


- (float) remainingTime
{
    float currentTimeInSeconds = (float)[[_mediaplayer time]intValue];
    float durationTimeInSeconds = currentTimeInSeconds - (float)[[_mediaplayer remainingTime]intValue];
    
    return (durationTimeInSeconds - currentTimeInSeconds) * 0.001;
    
}// remainingTime


- (int) durationInSeconds
{
    int durationTimeInSeconds = [[_mediaplayer time]intValue] * 0.001 - [[_mediaplayer remainingTime]intValue] * 0.001;
    return durationTimeInSeconds;
    
}// durationInSeconds

@end