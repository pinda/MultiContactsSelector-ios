//
//  SMContactsSelector.m
//  
//
//  Created by Sergio on 03/03/11.
//  Copyright 2011 Sergio. All rights reserved.
//

#import "SMContactsSelector.h"

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
@synthesize recordIDs;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    if ((requestData != DATA_CONTACT_TELEPHONE) && 
        (requestData != DATA_CONTACT_EMAIL) &&
        (requestData != DATA_CONTACT_ID))
    {
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
	if ([currentLanguage isEqualToString:@"es"])
	{
		arrayLetters = [[[NSArray spanishAlphabet] createList] retain];
        cancelItem.title = @"Cancelar";
        doneItem.title = @"Hecho";
        alertTitle = @"Selecciona";
	}
	else
	{
		arrayLetters = [[[NSArray englishAlphabet] createList] retain];
        cancelItem.title = NSLocalizedString(@"button:cancel", @"Cancel");
        doneItem.title = NSLocalizedString(@"button:done", @"Done");
        alertTitle = NSLocalizedString(@"alert:select", @"Select");
	}
    
	cancelItem.action = @selector(dismiss);
	doneItem.action = @selector(acceptAction);
	
	ABAddressBookRef addressBook = ABAddressBookCreate( );
	CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
	CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
	dataArray = [NSMutableArray new];
	
	for (int i = 0; i < nPeople; i++)
	{
		ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
		ABMultiValueRef property = ABRecordCopyValue(person, (requestData == DATA_CONTACT_TELEPHONE) ? kABPersonPhoneProperty : kABPersonEmailProperty);
        
		NSArray *propertyArray = (NSArray *)ABMultiValueCopyArrayOfAllValues(property);
		CFRelease(property);
        
		NSString *objs = @"";
        BOOL lotsItems = NO;
		for (int i = 0; i < [propertyArray count]; i++)
		{
			if (objs == @"") 
			{
				objs = [propertyArray objectAtIndex:i];
			}
			else 
			{
                lotsItems = YES;
				objs = [objs stringByAppendingString:[NSString stringWithFormat:@",%@", [propertyArray objectAtIndex:i]]];
			}
		}
        
		[propertyArray release];
        
		CFStringRef name;
        name = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        CFStringRef lastNameString;
        lastNameString = ABRecordCopyValue(person, kABPersonLastNameProperty);
        CFStringRef emailString;
        emailString = ABRecordCopyValue(person, kABPersonEmailProperty);
        
		NSString *nameString = (NSString *)name;
		NSString *lastName = (NSString *)lastNameString;
        int currentID = (int)ABRecordGetRecordID(person);
        
        if ((id)lastNameString != nil)
        {
            nameString = [NSString stringWithFormat:@"%@ %@", nameString, lastName];
        }
        
        NSMutableDictionary *info = [NSMutableDictionary new];
        [info setValue:[NSString stringWithFormat:@"%@", [[nameString stringByReplacingOccurrencesOfString:@" " withString:@""] substringToIndex:1]] forKey:@"letter"];
        [info setValue:[NSString stringWithFormat:@"%@", nameString] forKey:@"name"];
        [info setValue:@"-1" forKey:@"rowSelected"];
        [info setValue:[NSString stringWithFormat:@"%d", currentID] forKey:@"contactID"];
        
        if ((objs != @"") || ([[objs lowercaseString] rangeOfString:@"null"].location == NSNotFound))
		{
            if (requestData == DATA_CONTACT_EMAIL) 
            {
                [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"email"];
                
                if (!lotsItems) 
                {
                    [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"emailSelected"];
                }
                else
                {
                    [info setValue:@"" forKey:@"emailSelected"];
                }
            }
            
            if (requestData == DATA_CONTACT_TELEPHONE)
            {
                [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"telephone"];
                
                if (!lotsItems) 
                {
                    [info setValue:[NSString stringWithFormat:@"%@", objs] forKey:@"telephoneSelected"];
                }
                else
                {
                    [info setValue:@"" forKey:@"telephoneSelected"];
                }
            }
            
            if (requestData == DATA_CONTACT_ID) 
            {
                [info setValue:[NSString stringWithFormat:@"%d", currentID] forKey:@"recordID"];
                
                [info setValue:@"" forKey:@"recordIDSelected"];
            }
		}
        /*
        if ([recordIDs count] > 0) 
        {
            BOOL insert = ([[NSString stringWithFormat:@"%d", currentID] isRecordInArray:recordIDs]);
            
            if (insert)
            {
                [dataArray addObject:info];
            }
        }
        else
         */
        [dataArray addObject:info];
        
        [info release];
        if (name) CFRelease(name);
        if (lastNameString) CFRelease(lastNameString);
	}
	
	CFRelease(allPeople);
	CFRelease(addressBook);
    
	NSSortDescriptor *sortDescriptor;
	sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name"
												  ascending:YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	data = [[dataArray sortedArrayUsingDescriptors:sortDescriptors] retain];
	
    if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }
	
	self.searchDisplayController.searchResultsTableView.scrollEnabled = YES;
	self.searchDisplayController.searchBar.showsCancelButton = NO;
	
	NSMutableDictionary	*info = [NSMutableDictionary new];
	for (int i = 0; i < [arrayLetters count]; i++)
	{
		NSMutableArray *array = [NSMutableArray new];
		
		for (NSDictionary *dict in data)
		{
			NSString *name = [dict valueForKey:@"name"];
			name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
			
			if ([[[name substringToIndex:1] uppercaseString] isEqualToString:[arrayLetters objectAtIndex:i]]) 
			{
				[array addObject:dict];
			}
		}
		
		[info setValue:array forKey:[arrayLetters objectAtIndex:i]];
		[array release];
	}
	
	for (int i = 0; i < [arrayLetters count]; i++)
	{
		NSMutableArray *array = [NSMutableArray new];
		
		for (NSDictionary *dict in data)
		{
			NSString *name = [dict valueForKey:@"name"];
			name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
			
			if ((![name isLetter]) && (![name containsNullString]))
			{
				[array addObject:dict];
			}
		}
		
		[info setValue:array forKey:@"#"];
		[array release];
	}
    
	dataArray = [[NSMutableArray alloc] initWithObjects:info, nil];
	self.filteredListContent = [NSMutableArray arrayWithCapacity:[data count]];
	[self.searchDisplayController.searchBar setShowsCancelButton:NO];
	selectedRow = [NSMutableArray new];
	table.editing = NO;
	[info release];
	[self.table reloadData];
}

- (void)acceptAction
{
	NSMutableArray *objects = [NSMutableArray new];
    
	for (int i = 0; i < [arrayLetters count]; i++)
	{
		NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:i]];
		
		for (int x = 0; x < [obj count]; x++)
		{
			NSMutableDictionary *item = (NSMutableDictionary *)[obj objectAtIndex:x];
			BOOL checked = [[item objectForKey:@"checked"] boolValue];
            
			if (checked)
			{
                NSString *str = @"";
                
				if (requestData == DATA_CONTACT_TELEPHONE) 
                {
                    str = [item valueForKey:@"telephoneSelected"];
                    
                    if (![str isEqualToString:@""]) 
                    {
                        [objects addObject:str];
                    }
                }
                else if (requestData == DATA_CONTACT_EMAIL)
                {
                    str = [item valueForKey:@"emailSelected"];
                    
                    if (![str isEqualToString:@""]) 
                    {
                        [objects addObject:str];
                    }
                }
                else
                {
                    str = [item valueForKey:@"recordID"];
                    
                    if (![str isEqualToString:@""]) 
                    {
                        [objects addObject:str];
                    }
                }
			}
		}
	}
    
    if ([self.delegate respondsToSelector:@selector(numberOfRowsSelected:withData:andDataType:)]) 
        [self.delegate numberOfRowsSelected:[objects count] withData:objects andDataType:requestData];
    
    
	[objects release];
	[self dismiss];
}

- (void)dismiss
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
  if ([recordIDs count] > 0) {
    if ([recordIDs containsObject:[item objectForKey:@"contactID"]]) {
      checked = YES;
      
      [item setValue:@"1" forKey:@"checked"];
    }
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
      alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      alertView.delegate = self;
      [alertView show];
      [alertView release];
    } else {        
        [item setObject:[NSNumber numberWithBool:!checked] forKey:@"checked"];
        
        UITableViewCell *cell = [item objectForKey:@"cell"];
        UIButton *button = (UIButton *)cell.accessoryView;
        
        UIImage *newImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
        [button setBackgroundImage:newImage forState:UIControlStateNormal];
        
        if (tableView == self.searchDisplayController.searchResultsTableView)
        {
            [self.searchDisplayController.searchResultsTableView reloadData];
            [selectedRow addObject:item];
        }
    }
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if(buttonIndex == 1) {
    UITextField *input = [alertView textFieldAtIndex:0];
    
    if ([input.text length] == 0) {
		  NSString* message = [NSString stringWithFormat:NSLocalizedString(@"alert:email:input", @"Please enter %@'s email"), [selectedItem objectForKey:@"name"]];
      UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert:input:title", @"")
                                                          message:message 
                                                         delegate:nil 
                                                cancelButtonTitle:NSLocalizedString(@"alert:cancel", @"")
                                                otherButtonTitles:NSLocalizedString(@"alert:add", @""), nil];
      alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      alertView.delegate = self;
      [alertView show];
      [alertView release];
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
	
	NSArray *array = (NSArray *)[[dataArray objectAtIndex:0] valueForKey:sectionString];
    
	for (NSDictionary *dict in array)
	{
		NSString *name = [dict valueForKey:@"name"];
		name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
		
		if (![name isLetter]) 
		{
			i++;
		}
		else
		{
			if ([[[name substringToIndex:1] uppercaseString] isEqualToString:[arrayLetters objectAtIndex:section]]) 
			{
				i++;
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
    
	for (int i = 0; i < [arrayLetters count]; i++)
	{
		NSMutableArray *obj = [[dataArray objectAtIndex:0] valueForKey:[arrayLetters objectAtIndex:i]];
		
		for (int x = 0; x < [obj count]; x++)
		{
			NSMutableDictionary *item = (NSMutableDictionary *)[obj objectAtIndex:x];
			
			NSString *name = [[item valueForKey:@"name"] lowercaseString];
			name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
			
			NSComparisonResult result = [name compare:[searchText lowercaseString] options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
			if (result == NSOrderedSame)
			{
				[self.filteredListContent addObject:item];
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