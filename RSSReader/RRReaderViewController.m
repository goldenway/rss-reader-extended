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

#define READER_URL @"http://bash.im/rss/"
#define BG_COLOR [UIColor colorWithRed:0.8 green:0.8 blue:1.0 alpha:1.0]
#define TEXT_FONT [UIFont systemFontOfSize:14.0]
#define TEXT_WIDTH 280

@interface RRReaderViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UITableView *rssTableView;
@property (nonatomic, retain) NSMutableArray *items;

@end

@implementation RRReaderViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.items = [NSMutableArray array];
        
        //refresh button
        UIBarButtonItem* refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshData)];
        self.navigationItem.rightBarButtonItem = refreshButton;
        [refreshButton release];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = BG_COLOR;
    
    //table
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
    [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
    
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:READER_URL]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response,
                                               NSData* data,
                                               NSError* error)
     {
         if ([data length] > 0 && error == nil)
             [self showTableWithData:data];
         else if (error)
             [self showAlertWithMessage:@"Can't load data"];
     }];
}

- (void)showTableWithData:(NSData *)data
{
    NSError *error = nil;
    TBXML* tbxml = [[TBXML alloc] initWithXMLData:data error:&error];
    
    if (error)
    {
        [self showAlertWithMessage:@"Can't parse data"];
        
        [tbxml release];
        return;
    }
    
    [self.items removeAllObjects];
    
    TBXMLElement* channel = tbxml.rootXMLElement->firstChild;
    TBXMLElement *item = [TBXML childElementNamed:@"item" parentElement:channel];
    
    if (item == nil)
    {
        [self showAlertWithMessage:@"List is empty"];
        
        [tbxml release];
        return;
    }
    
    while (item)
    {
        NSString *text = [NSString stringWithCString:[TBXML childElementNamed:@"description" parentElement:item]->text
                                            encoding:NSWindowsCP1251StringEncoding];
        [self.items addObject:text];
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
    
    UIAlertView* errorAlert = [[[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] autorelease];
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* CellIdentifier = @"Cell";
    UITableViewCell* cell = [_rssTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    
    if (self.items) cell.textLabel.text = [NSString stringWithFormat:@"%@", [self.items objectAtIndex:indexPath.section]];
    else cell.textLabel.text = @"There are no items in list";
    
    cell.textLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = TEXT_FONT;
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* quote = [self.items objectAtIndex:indexPath.section];
    CGSize size = [quote sizeWithFont:TEXT_FONT constrainedToSize:CGSizeMake(TEXT_WIDTH, MAXFLOAT) lineBreakMode:0];
    
    return size.height;
}

- (void)dealloc
{
    self.rssTableView = nil;
    self.items = nil;
    
    [super dealloc];
}

@end
