

#import "ACDocument.h"
#import "PrioritySplitViewDelegate.h"
#import <AppKit/AppKit.h>

#define TYPE_XML        0
#define TYPE_FILE       1

@interface ACDocument(PrivateAPI)
- (void)setUpSplitViewDelegate;
- (BOOL)hasPointsDefined;
- (void)setUpPointMatrixForRows:(int)rows cols:(int)cols;
- (void)enableUI:(BOOL)enable;
@end


@implementation ACDocument

@synthesize pointMatrix, imageLoaded, sectionPopUpButton;

- (id)init
{
    self = [super init];
    if (self) {
		pointMatrix = [[NSMutableArray alloc] init];
		imageLoaded = NO;
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"ACDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	
	[self setUpSplitViewDelegate];
	
	[imageView setImageWithURL:	[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForImageResource:@"drop_sprite.png"]]];
	[imageView setCurrentToolMode: IKToolModeMove];
	[imageView setDoubleClickOpensImageEditPanel:NO];
	
	gridLayer = [ImageViewGridLayer layer];
	gridLayer.owner = imageView;
	gridLayer.document = self;
	
	[gridLayer setNeedsDisplay];
	
	[imageView setOverlay:gridLayer forType:IKOverlayTypeImage];
	imageView.supportsDragAndDrop = NO;
	
	NSWindow *window = [aController window];
	[window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	[window setDelegate:self];
	
	filePath = nil;
	gridOK = NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([NSImage canInitWithPasteboard:[sender draggingPasteboard]]) {
		return NSDragOperationCopy; //accept data
	}
	
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject:NSFilenamesPboardType])
	{
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		return [files count] == 1;
	}
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject:NSFilenamesPboardType])
	{
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		if([files count] == 1)
		{
			filePath = [files objectAtIndex:0];
			[imageView setImageWithURL:[NSURL fileURLWithPath:filePath]];
			imageLoaded = YES;
			[self enableUI:YES];
			[self updateGrid:self];
		}
	}
	return YES;
}

- (IBAction)updateGrid:(id)sender 
{
	int rows = [[rowsTextField stringValue] intValue];
	int cols = [[colsTextField stringValue] intValue];

	gridOK = rows > 0 && cols > 0;
	
	
	if (rows <= 50 && cols <= 50 && (rows != gridLayer.rows || cols != gridLayer.cols)) {
		if ([self hasPointsDefined]) {
			NSAlert *alert = [NSAlert alertWithMessageText:@"Reset all the vertices?"
											 defaultButton:@"Yes, reset them." alternateButton:@"Cancel"
											   otherButton:nil informativeTextWithFormat:@"Changing the number of rows and columns will reset all the vertices you have defined."];
			
			if ([alert runModal] != NSAlertDefaultReturn) {
				NSLog(@"clicked no");
				rowsTextField.stringValue = [NSString stringWithFormat:@"%i", gridLayer.rows];
				colsTextField.stringValue = [NSString stringWithFormat:@"%i", gridLayer.cols];
				
				return;
			}
		}
		
		//reset our array
		[self setUpPointMatrixForRows:rows cols:cols];
		
		gridLayer.rows = rows;
		gridLayer.cols = cols;
		[gridLayer setNeedsDisplay];
		[self updateResultTextField];
	}
}

- (IBAction)resetVertices:(id)sender
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Reset all the vertices?"
									 defaultButton:@"Yes, reset them." alternateButton:@"Cancel"
									   otherButton:nil informativeTextWithFormat:@""];
	
	if ([alert runModal] == NSAlertDefaultReturn) {
		int rows = [[rowsTextField stringValue] intValue];
		int cols = [[colsTextField stringValue] intValue];
		[self setUpPointMatrixForRows:rows cols:cols];
		[gridLayer setNeedsDisplay];
		[self updateResultTextField];
	}
}


- (IBAction)updateOutput:(id)sender
{
	[self updateResultTextField];
}

- (IBAction)makeAnnotatable:(id)sender 
{
	if ([(NSButton *)sender state] == NSOnState) {
		[imageView setCurrentToolMode: IKToolModeAnnotate];
	} else {
		[imageView setCurrentToolMode: IKToolModeMove];
	}

}

- (void)addPoint:(NSPoint)aPoint forRow:(int)aRow col:(int)aCol 
{   
    [[[[pointMatrix objectAtIndex:(aRow - 1)] objectAtIndex:(aCol - 1)] objectAtIndex:[sectionPopUpButton selectedTag]] addObject:[NSValue valueWithPoint:aPoint]];
    
	[gridLayer setNeedsDisplay];
	[self updateResultTextField];
}


- (void)updateResultTextField
{
	NSString *result = [NSString string];
    /*
     * lets do the name later!
	NSString *variableName = [variableTextField stringValue];
	
	if (!variableName || [variableName length] < 1) {
		variableName = @"verts";
	}
    */
    // write header to xml string
    result = [result stringByAppendingFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<ourNumberXml>\n\t<config>\n\t\t<language>DE</language>\n\t\t<origin>TOP LEFT</origin>\n\t\t<dectector type=\"cycle\" radius=\"15\"></dectector>\n\t</config>\n\n\t<numbers>\n"];
    
	
	for (int r = (int)[pointMatrix count] - 1; r >= 0; r--) {
        // iterate through all rows
		for (int c = 0; c < [[pointMatrix objectAtIndex:r] count]; c++) {
            // iterate through all columns
            // add comment for each image
            result = [result stringByAppendingFormat:@"\t\t<!-- row %i, column %i -->\n", ([pointMatrix count] - r), (c + 1)]; 
            
            // TODO fix number id and name!
            result = [result stringByAppendingFormat:@"\t\t<number id=\"1\" name=\"1\"\n\t\t\t<sections>\n"];
            
            for (int s = 0; s < 3; s++) {
                // iterate throug all sections - only those contain points!
                NSMutableArray *points = [[[pointMatrix objectAtIndex:r] objectAtIndex:c] objectAtIndex:s];

                result = [result stringByAppendingFormat:@"\t\t\t\t<section id=\"%i\">\n", s];
                // get all the points in this section
                for (int p = 0; p < [points count]; p++) {
//                    PathPoint *currentPathPoint = [points objectAtIndex:p];
//                    NSPoint point = currentPathPoint.location;
                    NSPoint point = [[points objectAtIndex:p] pointValue];
                    
                    result = [result stringByAppendingFormat:@"\t\t\t\t\t<p id=\"%i\" type=\"cycle\" center_x=\"%.1f\" center_y=\"%.1f\" radius=\"22.5\"/>\n", p, point.x, point.y];        
                }
                result = [result stringByAppendingFormat:@"\t\t\t\t</section>\n"];
                                
            } // end of section for-loop
            
            result = [result stringByAppendingFormat:@"\t\t\t</sections>\n"];
            // TODO
            result = [result stringByAppendingFormat:@"\t\t\t<size width=\"XXX\" height=\"XXX\">\n"];
            
            result = [result stringByAppendingFormat:@"\t\t</number>\n"];
            
        } // end of colum for-loop
        
    } // end of row for-loop
    
    // close xml string
    result = [result stringByAppendingFormat:@"\t</numbers>\n</ourNumberXml>\n"];
    
	[resultTextView setString: result];
}

- (BOOL)hasPointsDefined 
{
	for (int r = (int)[pointMatrix count] - 1; r >= 0; r--) {
		for (int c = 0; c < [[pointMatrix objectAtIndex:r] count]; c++) {
            for (int s = 0; s < 3; s++) {
                NSMutableArray *points = [[[pointMatrix objectAtIndex:r] objectAtIndex:c] objectAtIndex:s];
                
                if ([points count] > 0) {
                    return YES;
                }
            }
		}
	}
	
	return NO;
}

- (void)setUpPointMatrixForRows:(int)rows cols:(int)cols 
{
	[pointMatrix removeAllObjects];
	for (int r = 0; r < rows; r++) {
		[pointMatrix addObject:[NSMutableArray array]];
		for (int c = 0; c < cols; c++) {
			[[pointMatrix objectAtIndex:r] addObject:[NSMutableArray array]];
            for (int sections = 0; sections < 3; sections++) {
                [[[pointMatrix objectAtIndex:r] objectAtIndex:c] addObject:[NSMutableArray array]];
            }
		}
	}	
}

- (void)enableUI:(BOOL)enable
{
	[zoomInButton setEnabled:enable];
	[zoomOutButton setEnabled:enable];
	[actualSizeButton setEnabled:enable];
	[editModeCheckbox setEnabled:enable];
	
	[rowsTextField setEnabled:enable];
	[colsTextField setEnabled:enable];
	[variableTextField setEnabled:enable];
	[typePopUpButton setEnabled:enable];
	[sectionPopUpButton setEnabled:enable];
}

#pragma mark -
#pragma mark SplitViewDelegate Set Up 

- (void)setUpSplitViewDelegate 
{
	splitViewDelegate = [[PrioritySplitViewDelegate alloc] init];
	
	[splitViewDelegate setPriority:0 forViewAtIndex:0]; // top priority for top view
	[splitViewDelegate setMinimumLength:100 forViewAtIndex:0];
	[splitViewDelegate setPriority:1 forViewAtIndex:1];
	[splitViewDelegate setMinimumLength:[[[splitView subviews] objectAtIndex:1] frame].size.height forViewAtIndex:1];
	
	[splitView setDelegate:splitViewDelegate];
}

#pragma mark -
#pragma mark Menu Delegate Methods
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
	BOOL enable = NO;
	
    if ([menuItem action] == @selector(resetVertices:))
    {
		enable = self.imageLoaded;
    }
    else if ([menuItem action] == @selector(scanImage:))
    {
		enable = self.imageLoaded;
    }
    else
    {
        enable = [super validateMenuItem:menuItem]; 
    }
	
    return enable;
}



@end
