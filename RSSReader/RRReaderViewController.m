//
//  RRViewController.m
//  RSSReader
//
//  Created by goldenway on 12/3/12.
//  Copyright (c) 2012 goldenway. All rights reserved.
//

#import "RRReaderViewController.h"
#import "SVProgressHUD.h"
#import "TBXML.h"
#import "RRQuote.h"
#import "RRSharingCell.h"
#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#define READER_URL @"http://bash.im/rss/"
#define BG_COLOR [UIColor colorWithRed:200/255 green:200/255 blue:255/255 alpha:1.0]
#define TEXT_FONT [UIFont systemFontOfSize:14.0]
#define TEXT_WIDTH 280
#define SHARING_CELL_HEIGHT 37
#define QUOTE_CELL_DELTA_HEIGHT 20

@interface RRReaderViewController () <UITableViewDataSource, UITableViewDelegate, RRSharingCellDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UITableView *rssTableView;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) RRQuote *selectedItem;
@property (nonatomic, retain) UIActionSheet *sharingActionSheet;

@end

@implementation RRReaderViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.items = [NSMutableArray array];
        
        //refresh button
        UIBarButtonItem* refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                       target:self
                                                                                       action:@selector(refreshData)];
        self.navigationItem.rightBarButtonItem = refreshButton;
        [refreshButton release];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = BG_COLOR;
    
    _rssTableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  self.view.bounds.size.width,
                                                                  self.view.bounds.size.height - self.navigationController.navigationBar.bounds.size.height)
                                                 style:UITableViewStyleGrouped];
    self.rssTableView.delegate = self;
    self.rssTableView.dataSource = self;
    [self.view addSubview:self.rssTableView];
    
    [self loadingData];
}

- (void)loadingData
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...", @"ProgressHUD : loading") maskType:SVProgressHUDMaskTypeGradient];
    
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:READER_URL]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response,
                                               NSData* data,
                                               NSError* error)
     {
         if ([data length] > 0 && error == nil)
             [self showTableWithData:data];
         else if (error)
             [self showAlertWithMessage:NSLocalizedString(@"Can't load data", @"Request error")];
     }];
}

- (void)showTableWithData:(NSData *)data
{
    NSError *error = nil;
    TBXML* tbxml = [[TBXML alloc] initWithXMLData:data error:&error];
    
    if (error)
    {
        [self showAlertWithMessage:NSLocalizedString(@"Can't parse data", @"Parsing error")];
        
        [tbxml release];
        return;
    }
    
    [self.items removeAllObjects];
    
    TBXMLElement* channel = tbxml.rootXMLElement->firstChild;
    TBXMLElement *item = [TBXML childElementNamed:@"item" parentElement:channel];
    
    if (item == nil)
    {
        [self showAlertWithMessage:NSLocalizedString(@"List is empty", @"Empty list alert message")];
        
        [tbxml release];
        return;
    }
    
    while (item)
    {
        RRQuote *quote = [[[RRQuote alloc] init] autorelease];
        
        NSMutableString *numberStr = [NSMutableString stringWithCString:[TBXML childElementNamed:@"title" parentElement:item]->text
                                                               encoding:NSWindowsCP1251StringEncoding];
        NSRange range = [numberStr rangeOfString:@"#"];
        quote.number = [numberStr substringFromIndex:range.location];
        
        quote.text = [NSString stringWithCString:[TBXML childElementNamed:@"description" parentElement:item]->text
                                        encoding:NSWindowsCP1251StringEncoding];
        quote.link = [NSString stringWithCString:[TBXML childElementNamed:@"link" parentElement:item]->text
                                        encoding:NSWindowsCP1251StringEncoding];
        [self.items addObject:quote];
        
        item = item->nextSibling;
    }
    
    [tbxml release];
    
    [self.rssTableView reloadData];
    
    [SVProgressHUD dismiss];
}

- (void)refreshData
{
    [self loadingData];
    
    if ([self.items count])
        [self.rssTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)showAlertWithMessage:(NSString *)message
{
    [SVProgressHUD dismiss];
    
    UIAlertView* errorAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert message")
                                                          message:message
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil, nil] autorelease];
    [errorAlert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.items count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* SharingCellIdentifier = @"SharingCell";
    static NSString* QuoteCellIdentifier = @"QuoteCell";
    
    if (indexPath.row == 0)
    {
        RRSharingCell* sharingCell = [_rssTableView dequeueReusableCellWithIdentifier:SharingCellIdentifier];
        
        if (sharingCell == nil)
            sharingCell = [[[RRSharingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SharingCellIdentifier] autorelease];
        
        sharingCell.delegate = self;
        sharingCell.numberStr = ((RRQuote *)[self.items objectAtIndex:indexPath.section]).number;
        sharingCell.buttonTag = indexPath.section;
        sharingCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return sharingCell;
    }
    else
    {
        UITableViewCell* quoteCell = [_rssTableView dequeueReusableCellWithIdentifier:QuoteCellIdentifier];
        
        if (quoteCell == nil)
            quoteCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:QuoteCellIdentifier] autorelease];
        
        quoteCell.textLabel.text = ((RRQuote *)[self.items objectAtIndex:indexPath.section]).text;
        quoteCell.textLabel.numberOfLines = 0;
        quoteCell.textLabel.font = TEXT_FONT;
        quoteCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return quoteCell;
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return SHARING_CELL_HEIGHT;
    
    NSString* quoteText = ((RRQuote *)[self.items objectAtIndex:indexPath.section]).text;
    CGSize size = [quoteText sizeWithFont:TEXT_FONT constrainedToSize:CGSizeMake(TEXT_WIDTH, MAXFLOAT) lineBreakMode:0];
    return size.height + QUOTE_CELL_DELTA_HEIGHT;
}

#pragma mark - RRSharingCellDelegate methods

- (void)shareItemWithTag:(int)tag
{
    self.selectedItem = [self.items objectAtIndex:tag];
    
    self.sharingActionSheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share via", @"Sharing action sheet title")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Sharing action sheet cancel button")
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Twitter", @"Email", nil] autorelease];
    [self.sharingActionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 0:
            [self shareViaTweeter];
            break;
        case 1:
            [self shareViaEmail];
            break;
        default:
            break;
    }
}

#pragma mark - Tweeter sharing

- (void)shareViaTweeter
{
    if ([TWTweetComposeViewController canSendTweet])
    {
        TWTweetComposeViewController *tweetSheet = [[[TWTweetComposeViewController alloc] init] autorelease];
        [tweetSheet addURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", self.selectedItem.link]]];
        [tweetSheet setInitialText:[NSString stringWithFormat:@"%@", self.selectedItem.text]];
        
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry", @"Tweeter alert title")
                                                             message:NSLocalizedString(@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup", @"Tweeter alert message")
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
    }
}

#pragma mark - Email sharing

- (void)shareViaEmail
{
	//checking whether the current device is configured for sending emails
    if ([MFMailComposeViewController canSendMail])
        [self displayComposerSheet];
    else
    {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"Email alert title")
                                                             message:NSLocalizedString(@"Your device is not configured for sending emails", @"Email alert message")
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil] autorelease];
        [alertView show];
    }
}

- (void)displayComposerSheet
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	[picker setSubject:NSLocalizedString(@"Quote from bash.im", @"Email subject")];
	[picker setMessageBody:[NSString stringWithFormat:@"%@\n\n%@", self.selectedItem.text, self.selectedItem.link] isHTML:YES];
	
    [self presentViewController:picker animated:YES completion:nil];
    [picker release];
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    NSString *message;
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message = NSLocalizedString(@"Canceled", @"Email result : cancelled");
			break;
		case MFMailComposeResultSaved:
			message = NSLocalizedString(@"Your message has been saved", @"Email result : saved");
			break;
		case MFMailComposeResultSent:
			message = NSLocalizedString(@"Your message has been sent", @"Email result : sent");
			break;
		case MFMailComposeResultFailed:
			message = NSLocalizedString(@"Failed", @"Email result : failed");
			break;
		default:
			message = NSLocalizedString(@"Not sent", @"Email result : other");
			break;
	}

	[self dismissViewControllerAnimated:YES completion:^
    {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
    }];
}

- (void)dealloc
{
    self.rssTableView = nil;
    self.items = nil;
    self.sharingActionSheet = nil;
    
    [super dealloc];
}

@end
