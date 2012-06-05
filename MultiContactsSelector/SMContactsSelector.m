//
//  SMContactsSelector.m
//  
//
//  Created by Sergio on 03/03/11.
//  Copyright 2011 Sergio. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "SMContactsSelector.h"
#import "TSAlertView.h"
#import "ABContactsHelper.h"
#import "ABContact.h"

@interface NSArray (Alphabet)

+ (NSArray *)spanishAlphabet;

+ (NSArray *)englishAlphabet;

- (NSMutableArray *)createList;

- (NSArray *)castToArray;

- (NSMutableArray *)castToMutableArray;

- (NSMutableArray *)createList;

@end

@implementation NSArray (Alphabet)

+ (NSArray *)spanishAlphabet
{
  NSArray *letters = [[NSArray alloc] initWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"Ñ", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
  
  NSArray *aux = [NSArray arrayWithArray:letters];
  [letters release];
  return aux;    
}

+ (NSArray *)englishAlphabet
{
  NSArray *letters = [[NSArray alloc] initWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
  
  NSArray *aux = [NSArray arrayWithArray:letters];
  [letters release];
  return aux;    
}

- (NSMutableArray *)createList
{
  NSMutableArray *list = [[NSMutableArray alloc] initWithArray:self];
  [list addObject:@"#"];
  
  NSMutableArray *aux = [NSMutableArray arrayWithArray:list];
  [list release];
  return aux;
}

- (NSArray *)castToArray
{
  if ([self isKindOfClass:[NSMutableArray class]])
  {
    NSArray *a = [[NSArray alloc] initWithArray:self];
    NSArray *aux = [NSArray arrayWithArray:a];
    [a release];
    return aux;
  }
  
  return nil;
}

- (NSMutableArray *)castToMutableArray
{
  if ([self isKindOfClass:[NSArray class]])
  {
    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:self];
    NSMutableArray *aux = [NSMutableArray arrayWithArray:a];
    [a release];
    return aux;
  }
  
  return nil;
}

@end

@interface NSString (character)

- (BOOL)isLetter;

- (BOOL)isRecordInArray:(NSArray *)array;

@end

@implementation NSString (character)

- (BOOL)isLetter
{
  NSArray *letters = [NSArray spanishAlphabet]; //replace by your alphabet
  BOOL isLetter = NO;
  
  for (int i = 0; i < [letters count]; i++)
  {
    if ([[[self substringToIndex:1] uppercaseString] isEqualToString:[letters objectAtIndex:i]]) 
    {
      isLetter = YES;
      break;
    }
  }
  
  return isLetter;
}

- (BOOL)isRecordInArray:(NSArray *)array
{
  for (NSString *str in array)
  {
    if ([self isEqualToString:str]) 
    {
      return YES;
    }
  }
  
  return NO;
}

@end

@implementation SMContactsSelector
@synthesize table;
@synthesize cancelItem;
@synthesize doneItem;
@synthesize delegate;
@synthesize filteredListContent;
@synthesize savedSearchTerm;
@synthesize savedScopeButtonIndex;
@synthesize searchWasActive;
@synthesize data;
@synthesize barSearch;
@synthesize alertTable;
@synthesize selectedItem;
@synthesize currentTable;
@synthesize arrayLetters;
@synthesize requestData;
@synthesize alertTitle;
@synthesize tokens;
@synthesize recordIDs;
@synthesize hiddenIDs;

- (void)loadContacts {
  dispatch_queue_t queue = dispatch_queue_create("com.Invy.multiContacts", 0);
  dispatch_async(queue, ^{
    NSMutableDictionary* letterInfo = [NSMutableDictionary new];
    NSArray* sortedContacts = [[ABContactsHelper contacts] sortedArrayUsingSelector:@selector(compareByName:)];
    
    for (ABContact* contact in sortedContacts) {      
      NSMutableDictionary *info = [NSMutableDictionary new];

      NSString *name = contact.fullName;
      if ([name length] == 0) {
        name = contact.contactName;
      }
      
      // If name is still nil add email
      if ([name length] == 0) {
        if ([contact.emailArray count] > 0) {
          name = [contact.emailArray lastObject];
        } else {
          name = @"-";
        }
      }
      NSString* firstLetter = [[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringToIndex:1];
      
      [info setValue:firstLetter forKey:@"letter"];
      [info setValue:[NSString stringWithFormat:@"%@", name] forKey:@"name"];
      [info setValue:@"-1" forKey:@"rowSelected"];
      [info setValue:[NSString stringWithFormat:@"%d", (int)contact.recordID] forKey:@"contactID"];
      
      NSString *objs = @"";
      BOOL lotsItems = NO;
      for (int i = 0; i < [contact.emailArray count]; i++) {
        if (objs == @"") {
          objs = [contact.emailArray objectAtIndex:i];
        } else {
          lotsItems = YES;
          objs = [objs stringByAppendingString:[NSString stringWithFormat:@",%@", [contact.emailArray objectAtIndex:i]]];
        }
      }

      if ((objs != @"") || ([[objs lowercaseString] rangeOfString:@"null"].location == NSNotFound)) {
        if (requestData == DATA_CONTACT_EMAIL) {
          [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"email"];
          
          if (!lotsItems) {
            [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"emailSelected"];
          } else {
            [info setValue:@"" forKey:@"emailSelected"];
          }
        }
        
        if (requestData == DATA_CONTACT_TELEPHONE) {
          [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"telephone"];
          
          if (!lotsItems) {
            [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"telephoneSelected"];
          } else {
            [info setValue:@"" forKey:@"telephoneSelected"];
          }
        }
        
        if (requestData == DATA_CONTACT_ID) {
          [info setValue:[NSString stringWithFormat:@"%d", (int)contact.recordID] forKey:@"recordID"];
          
          [info setValue:@"" forKey:@"recordIDSelected"];
        }
        
        for (NSDictionary* token in self.tokens) {
          if ([token isKindOfClass:[NSDictionary class]] && [[token objectForKey:@"id"] isEqualToString:[info objectForKey:@"contactID"]]) {
            [info setValue:[NSNumber numberWithBool:YES] forKey:@"checked"];
            [info setValue:[token objectForKey:@"email"] forKey:@"emailSelected"];
          }
        }
          
        // Append to array based on first letter
        if ([arrayLetters containsObject:firstLetter]) {
          if ([letterInfo objectForKey:firstLetter]) {
            [[letterInfo objectForKey:firstLetter] addObject:info];
          } else {
            NSMutableArray* arrayForLetter = [[NSMutableArray alloc] initWithObjects:info, nil];
            [letterInfo setValue:arrayForLetter forKey:firstLetter];
          }
        } else {
          if ([letterInfo objectForKey:@"#"]) {
            [[letterInfo objectForKey:@"#"] addObject:info];
          } else {
            NSMutableArray* arrayForLetter = [[NSMutableArray alloc] initWithObjects:info, nil];
            [letterInfo setValue:arrayForLetter forKey:@"#"];
          }
        }
      }
      
      if (![self.hiddenIDs containsObject:[info objectForKey:@"contactID"]]) {
        [dataArray addObject:info];
      }
      
      [info release];
    }
    
    if (self.savedSearchTerm) {
      [self.searchDisplayController setActive:self.searchWasActive];
      [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
      [self.searchDisplayController.searchBar setText:savedSearchTerm];
      
      self.savedSearchTerm = nil;
    }
    
    self.searchDisplayController.searchResultsTableView.scrollEnabled = YES;
    self.searchDisplayController.searchBar.showsCancelButton = NO;
    
    data = [[NSArray arrayWithArray:dataArray] retain];
    dataArray = [[NSMutableArray alloc] initWithObjects:letterInfo, nil];
    self.filteredListContent = [NSMutableArray arrayWithCapacity:[data count]];
    [self.searchDisplayController.searchBar setShowsCancelButton:NO];
    selectedRow = [NSMutableArray new];
    table.editing = NO;
    [letterInfo release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      //Update the UI
      [self.table reloadData];
      [self.searchDisplayController.searchBar setUserInteractionEnabled:YES];
      
      [modalView setHidden:YES];
      [activityIndicator stopAnimating];
    });
  });
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  forceReload = YES;
  
  [self.table reloadData];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.searchDisplayController.searchBar setUserInteractionEnabled:NO];
  
  if ((requestData != DATA_CONTACT_TELEPHONE) && 
      (requestData != DATA_CONTACT_EMAIL) &&
      (requestData != DATA_CONTACT_ID)) {
    [self.navigationController dismissModalViewControllerAnimated:YES];
    
    @throw ([NSException exceptionWithName:@"Undefined data request"
                                    reason:@"Define requestData variable (EMAIL or TELEPHONE)" 
                                  userInfo:nil]);
  }
  
  NSString *currentLanguage = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0] lowercaseString];
  
  // Jetzt Spanisch und Englisch nur
  // Por el momento solo ingles y español
  // At the moment only Spanish and English
  // replace by your alphabet
  if ([currentLanguage isEqualToString:@"es"]) {
    arrayLetters = [[[NSArray spanishAlphabet] createList] retain];
    cancelItem.title = @"Cancelar";
    doneItem.title = @"Hecho";
    alertTitle = @"Selecciona";
  } else {
    arrayLetters = [[[NSArray englishAlphabet] createList] retain];
    cancelItem.title = NSLocalizedString(@"button:cancel", @"Cancel");
    doneItem.title = NSLocalizedString(@"button:done", @"Done");
    alertTitle = NSLocalizedString(@"alert:select", @"Select");
  }
  
  cancelItem.action = @selector(dismiss);
  doneItem.action = @selector(acceptAction);
  
  dataArray = [NSMutableArray new];
  
  // Start loading contacts
  [self loadContacts];
  
  // Add modal loading window
  modalView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2) - 50, 
                                                      (self.view.frame.size.height / 2) - 50, 
                                                      100,
                                                       100)];
  modalView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
  modalView.layer.cornerRadius = 5.0f;  
  
  UILabel* loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, modalView.frame.size.height - 20, modalView.frame.size.width - 10, 10)];
  loadingLabel.text = NSLocalizedString(@"smcontactsselector:loading", @"Loading contacts...");
  loadingLabel.textAlignment = UITextAlignmentCenter;
  loadingLabel.textColor = [UIColor whiteColor];
  loadingLabel.backgroundColor = [UIColor clearColor];
  loadingLabel.font = [UIFont systemFontOfSize:10.0];
  [modalView addSubview:loadingLabel];
  
  // Add activity indicator
  activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  activityIndicator.center = CGPointMake(modalView.frame.size.width / 2, modalView.frame.size.height / 2);
  [activityIndicator startAnimating];
  [modalView addSubview:activityIndicator];
  
  [self.view addSubview:modalView];
}

- (void)acceptAction
{
  if ([dataArray count] > 0) {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"checked == 1"];
    NSMutableArray* checkedArray = [NSMutableArray arrayWithArray:[data filteredArrayUsingPredicate:predicate]];
    
    if ([self.delegate respondsToSelector:@selector(numberOfRowsSelected:withData:andDataType:)]) 
      [self.delegate numberOfRowsSelected:[checkedArray count] withData:checkedArray andDataType:requestData];
  }
  forceReload = NO;
  [self dismiss];
}

- (void)dismiss
{
  [self dismissModalViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  forceReload = NO;
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    [self tableView:self.searchDisplayController.searchResultsTableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
  }
  else
  {
    [self tableView:self.table accessoryButtonTappedForRowWithIndexPath:indexPath];
    [self.table deselectRowAtIndexPath:indexPath animated:YES];
  }	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *kCustomCellID = @"MyCellID";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomCellID];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCustomCellID] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  }
  
  NSMutableDictionary *item = nil;
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    item = (NSMutableDictionary *)[self.filteredListContent objectAtIndex:indexPath.row];
  }
  else
  {
    NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:indexPath.section]];
    
    item = (NSMutableDictionary *)[obj objectAtIndex:indexPath.row];
  }
  
  cell.textLabel.text = [item objectForKey:@"name"];
  cell.textLabel.adjustsFontSizeToFitWidth = YES;
  
  [item setObject:cell forKey:@"cell"];
  
  BOOL checked = NO;  
  if ([self.recordIDs count] > 0 && forceReload) {
    if ([self.recordIDs containsObject:[item objectForKey:@"contactID"]]) {
      checked = YES;
      
      [item setValue:[NSNumber numberWithBool:YES] forKey:@"checked"];
    } else {
      checked = NO;
      
      [item setValue:[NSNumber numberWithBool:NO] forKey:@"checked"];
    }
  } else if ([self.recordIDs count] == 0 && forceReload) {
    checked = NO;
    
    [item setValue:[NSNumber numberWithBool:NO] forKey:@"checked"];
  } else {
    checked = [[item objectForKey:@"checked"] boolValue];
  }

  UIImage *image = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
  button.frame = frame;
  
  if (tableView == self.searchDisplayController.searchResultsTableView) 
  {
    button.userInteractionEnabled = NO;
  }
  
  [button setBackgroundImage:image forState:UIControlStateNormal];
  
  [button addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
  cell.backgroundColor = [UIColor clearColor];
  cell.accessoryView = button;
  
  return cell;
}

- (void)checkButtonTapped:(id)sender event:(id)event
{
  NSSet *touches = [event allTouches];
  UITouch *touch = [touches anyObject];
  CGPoint currentTouchPosition = [touch locationInView:self.table];
  NSIndexPath *indexPath = [self.table indexPathForRowAtPoint: currentTouchPosition];
  
  if (indexPath != nil)
  {
    [self tableView: self.table accessoryButtonTappedForRowWithIndexPath: indexPath];
  }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{	
  NSMutableDictionary *item = nil;
  
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    item = (NSMutableDictionary *)[filteredListContent objectAtIndex:indexPath.row];
  }
  else
  {
    NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:indexPath.section]];
    item = (NSMutableDictionary *)[obj objectAtIndex:indexPath.row];
  }
  
  NSArray *objectsArray = nil;
  
  if (requestData == DATA_CONTACT_TELEPHONE)
    objectsArray = (NSArray *)[[item valueForKey:@"telephone"] componentsSeparatedByString:@","];
  else if (requestData == DATA_CONTACT_EMAIL)
    objectsArray = (NSArray *)[[item valueForKey:@"email"] componentsSeparatedByString:@","];
  else
    objectsArray = (NSArray *)[[item valueForKey:@"recordID"] componentsSeparatedByString:@","];
  
  int objectsCount = [objectsArray count];
  BOOL checked = [[item objectForKey:@"checked"] boolValue];
  
  if (objectsCount > 1)
  {
    selectedItem = item;
    self.currentTable = tableView;
    
    alertTable = [[AlertTableView alloc] initWithCaller:self 
                                                   data:objectsArray 
                                                  title:alertTitle
                                                context:self
                                             dictionary:item
                                                section:indexPath.section
                                                    row:indexPath.row];
    
    [alertTable show];
    [alertTable release];
  } else if ([[objectsArray lastObject] isEqualToString:@""] && !checked) {
    selectedItem = item;
    NSString* message = [NSString stringWithFormat:NSLocalizedString(@"alert:email:input", @"Please enter %@'s email"), [item objectForKey:@"name"]];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert:input:title", @"")
                                                        message:message 
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"alert:cancel", @"")
                                              otherButtonTitles:NSLocalizedString(@"alert:add", @""), nil];
    
    if ([alertView respondsToSelector:@selector(setAlertViewStyle:)]) {
      alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      alertView.delegate = self;
      [alertView show];
      [alertView release];
    } else {
      [alertView release];
      TSAlertView* av = [[[TSAlertView alloc] init] autorelease];
      av.title = NSLocalizedString(@"alert:input:title", @"");
      av.message = message;
      av.style = TSAlertViewStyleInput;
      av.delegate = self;
      
      // Add buttons
      [av addButtonWithTitle:NSLocalizedString(@"alert:cancel", @"")];
      [av addButtonWithTitle:NSLocalizedString(@"alert:add", @"")];
      av.cancelButtonIndex = 0;
      
      [av show];
      
      if (tableView == self.searchDisplayController.searchResultsTableView) {
        av.frame = CGRectMake(av.frame.origin.x, av.frame.origin.y - 100, av.frame.size.width, av.frame.size.height);
      }
    }
    
  } else {        
    [item setObject:[NSNumber numberWithBool:!checked] forKey:@"checked"];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIButton *button = (UIButton *)cell.accessoryView;

    UIImage *newImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
    [button setBackgroundImage:newImage forState:UIControlStateNormal];

    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
      [selectedRow addObject:item];

      [self.searchDisplayController.searchResultsTableView reloadData];
    }
  }
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if(buttonIndex == 1) {
    UITextField* input;
    if ([alertView respondsToSelector:@selector(textFieldAtIndex:)]) {
      input = [alertView textFieldAtIndex:0];
    } else {
      TSAlertView* av = (TSAlertView*)alertView;
      input = av.inputTextField;
    }
    
    if ([input.text length] == 0) {
      NSString* message = [NSString stringWithFormat:NSLocalizedString(@"alert:email:input", @"Please enter %@'s email"), [selectedItem objectForKey:@"name"]];
      UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert:input:title", @"")
                                                          message:message 
                                                         delegate:self 
                                                cancelButtonTitle:NSLocalizedString(@"alert:cancel", @"")
                                                otherButtonTitles:NSLocalizedString(@"alert:add", @""), nil];
      if ([alertView respondsToSelector:@selector(setAlertViewStyle:)]) {
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
        [alertView release];
      } else {
        [alertView release];
        TSAlertView* av = [[[TSAlertView alloc] init] autorelease];
        av.title = NSLocalizedString(@"alert:input:title", @"");
        av.message = message;
        av.style = TSAlertViewStyleInput;
        av.delegate = self;
        
        // Add buttons
        [av addButtonWithTitle:NSLocalizedString(@"alert:cancel", @"")];
        [av addButtonWithTitle:NSLocalizedString(@"alert:add", @"")];
        av.cancelButtonIndex = 0;
        
        [av show];
      }
      
    } else {
      // Set row as selected
      BOOL checked = [[selectedItem objectForKey:@"checked"] boolValue];
      [selectedItem setObject:[NSNumber numberWithBool:!checked] forKey:@"checked"];
      (requestData == DATA_CONTACT_TELEPHONE) ? [selectedItem setValue:input.text forKey:@"telephoneSelected"] : [selectedItem setValue:input.text forKey:@"emailSelected"];
      
      UITableViewCell *cell = [selectedItem objectForKey:@"cell"];
      UIButton *button = (UIButton *)cell.accessoryView;
      
      UIImage *newImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
      [button setBackgroundImage:newImage forState:UIControlStateNormal];
      
      // Set off delegate method
      if ([self.delegate respondsToSelector:@selector(dataAddedTo:withData:andDataType:)]) 
        [self.delegate dataAddedTo:selectedItem withData:input.text andDataType:requestData];
    }
  } else {
    selectedItem = nil;
    return;
  }
}

#pragma mark
#pragma mark AlertTableViewDelegate delegate method

- (void)didSelectRowAtIndex:(NSInteger)row 
                    section:(NSInteger)section
                withContext:(id)context
                       text:(NSString *)text 
                    andItem:(NSMutableDictionary *)item
                        row:(int)rowSelected
{
  if ([text isEqualToString:@"-1"])
  {
    selectedItem = nil;
    return;
  }
  else if ([text isEqualToString:@"-2"])
  {
    (requestData == DATA_CONTACT_TELEPHONE) ? [selectedItem setValue:@"" forKey:@"telephoneSelected"] : [selectedItem setValue:@"" forKey:@"emailSelected"];
    [selectedItem setObject:[NSNumber numberWithBool:NO] forKey:@"checked"];
    [selectedItem setValue:@"-1" forKey:@"rowSelected"];
    UITableViewCell *cell = [selectedItem objectForKey:@"cell"];
    UIButton *button = (UIButton *)cell.accessoryView;
    
    UIImage *newImage = [UIImage imageNamed:@"unchecked.png"];
    [button setBackgroundImage:newImage forState:UIControlStateNormal];
  }
  else
  {
    (requestData == DATA_CONTACT_TELEPHONE) ? [selectedItem setValue:text forKey:@"telephoneSelected"] : [selectedItem setValue:text forKey:@"emailSelected"];
    [selectedItem setObject:[NSNumber numberWithBool:YES] forKey:@"checked"];
    
    UITableViewCell *cell = [selectedItem objectForKey:@"cell"];
    UIButton *button = (UIButton *)cell.accessoryView;
    
    UIImage *newImage = [UIImage imageNamed:@"checked.png"];
    [button setBackgroundImage:newImage forState:UIControlStateNormal]; 
    
    if (self.currentTable == self.searchDisplayController.searchResultsTableView)
    {
      [self.searchDisplayController.searchResultsTableView reloadData];
      [selectedRow addObject:selectedItem];
    }
  }
  
  if (self.currentTable == self.searchDisplayController.searchResultsTableView)
  {
    [filteredListContent replaceObjectAtIndex:rowSelected withObject:item];
  }
  else
  {
    NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:section]];
    [obj replaceObjectAtIndex:rowSelected withObject:item];
  }
  
  selectedItem = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  if (tableView == self.searchDisplayController.searchResultsTableView)
    return [self.filteredListContent count];
  
  int i = 0;
  NSString *sectionString = [arrayLetters objectAtIndex:section];
  
  if ([dataArray count] > 0) {
    NSArray *array = (NSArray *)[[dataArray objectAtIndex:0] valueForKey:sectionString];
  
    for (NSDictionary *dict in array) {
      NSString *name = [dict valueForKey:@"name"];
      name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
    
      if (![name isLetter]) {
        i++;
      } else {
        if ([[[name substringToIndex:1] uppercaseString] isEqualToString:[arrayLetters objectAtIndex:section]]) {
          i++;
        }
      }
    }
  }
  
  return i;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    return nil;
  }
  
  return arrayLetters;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    return 0;
  }
  
  return [arrayLetters indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    return 1;
  }
  
  return [arrayLetters count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{	
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    return @"";
  }
  
  return [arrayLetters objectAtIndex:section];
}

#pragma mark -
#pragma mark Content Filtering

- (void)displayChanges:(BOOL)yesOrNO
{
  int elements = [filteredListContent count];
  NSMutableArray *selected = [NSMutableArray new];
  for (int i = 0; i < elements; i++)
  {
    NSMutableDictionary *item = (NSMutableDictionary *)[filteredListContent objectAtIndex:i];
    
    BOOL checked = [[item objectForKey:@"checked"] boolValue];
    
    if (checked)
    {
      [selected addObject:item];
    }
  }
  
  for (int i = 0; i < [arrayLetters count]; i++)
  {
    NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:i]];
    
    for (int x = 0; x < [obj count]; x++)
    {
      NSMutableDictionary *item = (NSMutableDictionary *)[obj objectAtIndex:x];
      
      if (yesOrNO)
      {
        for (NSDictionary *d in selected)
        {
          if (d == item)
          {
            [item setObject:[NSNumber numberWithBool:yesOrNO] forKey:@"checked"];
          }
        }
      }
      else 
      {
        for (NSDictionary *d in selectedRow)
        {
          if (d == item)
          {
            [item setObject:[NSNumber numberWithBool:yesOrNO] forKey:@"checked"];
          }
        }
      }
    }
  }
  
  [selected release];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar
{
  selectedRow = [NSMutableArray new];
  [self.searchDisplayController.searchBar setShowsCancelButton:NO];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)_searchBar
{
  selectedRow = nil;
  [self displayChanges:NO];
  [self.searchDisplayController setActive:NO];
  [self.table reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)_searchBar
{
  [self displayChanges:YES];
  [self.searchDisplayController setActive:NO];
  [self.table reloadData];
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString*)scope
{
  [self.filteredListContent removeAllObjects];
  
  if ([dataArray count] > 0) {
    for (int i = 0; i < [arrayLetters count]; i++) {
      NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:i]];
    
      for (int x = 0; x < [obj count]; x++) {
        NSMutableDictionary *item = (NSMutableDictionary *)[obj objectAtIndex:x];
      
        NSString *name = [[item valueForKey:@"name"] lowercaseString];
        name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
      
        NSComparisonResult result = [name compare:[searchText lowercaseString] options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
        if (result == NSOrderedSame) {
          [self.filteredListContent addObject:item];
        }
      }
    }
  }
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
  [self filterContentForSearchText:searchString scope:
   [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
  
  return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
  [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
   [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
  
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)dealloc
{
  [data release];
  [filteredListContent release];
  [dataArray release];
  [arrayLetters release];
  [super dealloc];
}

@end