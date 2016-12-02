#import "MessagesViewController.h"

#import "ContactDetailsViewController.h"

#import "Helper.h"
#import "MEGAMessage.h"

@interface MessagesViewController () <JSQMessagesViewAccessoryButtonDelegate, JSQMessagesComposerTextViewPasteDelegate>

@property (nonatomic, strong) NSMutableArray *indexesMessages;
@property (nonatomic, strong) NSMutableDictionary *messagesDictionary;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (nonatomic, strong) MEGAMessage *editMessage;

@end

@implementation MessagesViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.indexesMessages = [[NSMutableArray alloc] init];
    self.messagesDictionary = [[NSMutableDictionary alloc] init];
    
    if ([[MEGASdkManager sharedMEGAChatSdk] openChatRoom:self.chatRoom.chatId delegate:self]) {        
        MEGALogDebug(@"Chat room opened");
        [self loadMessages];
    } else {
        MEGALogDebug(@"The delegate is NULL or the chatroom is not found");
    }
    
    self.title = self.chatRoom.title;
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
     //Set up message accessory button delegate and configuration
    self.collectionView.accessoryDelegate = self;
    
    self.showLoadEarlierMessagesHeader = YES;
    
    
     //Register custom menu actions for cells.
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(editAction:megaMessage:)];
    
    
     //Allow cells to be deleted
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    
    [self customNavigationBarLabel];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor mnz_grayE3E3E3]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor whiteColor]];
    
    self.collectionView.backgroundColor = [UIColor mnz_grayF5F5F5];
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:kFont size:14.0f];
    
    self.tabBarController.tabBar.hidden = YES;
    
    [self customToolbarContentView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:self.chatRoom.chatId delegate:self];
}

#pragma mark - Private methods

- (void)loadMessages {
    NSInteger loadMessage = [[MEGASdkManager sharedMEGAChatSdk] loadMessagesForChat:self.chatRoom.chatId count:16];
    switch (loadMessage) {
        case 0:
            MEGALogDebug(@"There's no more history available");
            break;
            
        case 1:
            MEGALogDebug(@"Messages will be fetched locally");
            break;
            
        case 2:
            MEGALogDebug(@"Messages will be requested to the server");
            break;
            
        default:
            break;
    }
}

- (void)customNavigationBarLabel {
    NSString *chatRoomState;
    switch (self.chatRoom.onlineStatus) {
        case MEGAChatRoomStateOffline:
            chatRoomState = AMLocalizedString(@"offline", @"");
            break;
        case MEGAChatRoomStateOnline:
            chatRoomState = AMLocalizedString(@"online", @"");
            break;
    }
    
    UILabel *label = [Helper customChatNavigationBarLabelWithTitle:self.chatRoom.title subtitle:chatRoomState];
    label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
    [self.navigationItem setTitleView:label];
    
    label.userInteractionEnabled = YES;
    label.superview.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *titleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomTitleDidTap)];
    label.gestureRecognizers = @[titleTapRecognizer];
}

- (void)customToolbarContentView {
    UIImage *image = [UIImage imageNamed:@"add"];
    UIButton *attachButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachButton setImage:image forState:UIControlStateNormal];
    [attachButton setFrame:CGRectMake(30, 0, 22, 22)];
    self.inputToolbar.contentView.leftBarButtonItem = attachButton;

    image = [UIImage imageNamed:@"send"];
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton setImage:image forState:UIControlStateNormal];
    [sendButton setFrame:CGRectMake(0, 0, 22, 22)];
    self.inputToolbar.contentView.rightBarButtonItem = sendButton;
}

- (BOOL)showDateBetweenMessage:(MEGAMessage *)message previousMessage:(MEGAMessage *)previousMessage {
    if ((previousMessage.senderId != message.senderId) || (previousMessage.date != message.date)) {
        NSDateComponents *previousDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:previousMessage.date];
        NSDateComponents *currentDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:message.date];
        if (previousDateComponents.day != currentDateComponents.day || previousDateComponents.month != currentDateComponents.month || previousDateComponents.year != currentDateComponents.year) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)showHourForMessage:(MEGAMessage *)message withIndexPath:(NSIndexPath *)indexPath {
    BOOL showHour = NO;
    MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:(indexPath.item - 1)]];
    if ([message.senderId isEqualToString:previousMessage.senderId]) {
        if ([self showHourBetweenDate:message.date previousDate:previousMessage.date]) {
            showHour = YES;
        } else {
            //TODO: Improve algorithm it has some issues when going back on the messages history
            NSUInteger count = self.indexesMessages.count;
            for (NSUInteger i = 1; i < count; i++) {
                NSInteger index = (indexPath.item - (i + 1));
                if (index > 0) {
                    MEGAMessage *messagePriorToThePreviousOne = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:index]];
                    if (messagePriorToThePreviousOne.index < 0) {
                        break;
                    }
                    
                    if ([message.senderId isEqualToString:messagePriorToThePreviousOne.senderId]) {
                        if ([self showHourBetweenDate:message.date previousDate:messagePriorToThePreviousOne.date]) {
                            JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                            if (cell.messageBubbleTopLabel == nil) {
                                showHour = NO;
                            } else {
                                showHour = YES;
                            }
                            break;
                        }
                    } else { // The timestamp should not appear because is already shown on the previous message
                        showHour = NO;
                        break;
                    }
                }
            }
        }
    } else { //If the previous message is from other sender, show timestamp
        showHour = YES;
    }
    
    return showHour;
}

- (BOOL)showHourBetweenDate:(NSDate *)date previousDate:(NSDate *)previousDate {
    NSUInteger numberOfSecondsToShowHour = (60 * 6) - 1;
    NSTimeInterval timeDifferenceBetweenMessages = [date timeIntervalSinceDate:previousDate];
    if (timeDifferenceBetweenMessages > numberOfSecondsToShowHour) {
        return YES;
    }

    return NO;
}

- (void)chatRoomTitleDidTap {
    if (self.chatRoom.isGroup) {
        //TODO: Group chat details
    } else {
        NSString *peerEmail = [[MEGASdkManager sharedMEGAChatSdk] userEmailByUserHandle:[self.chatRoom peerHandleAtIndex:0]];
        NSString *peerFirstname = [self.chatRoom peerFirstnameAtIndex:0];
        NSString *peerLastname = [self.chatRoom peerLastnameAtIndex:0];
        NSString *peerName = [NSString stringWithFormat:@"%@ %@", peerFirstname, peerLastname];
        uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:0];
        
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromChat;
        contactDetailsVC.chatId = self.chatRoom.chatId;
        contactDetailsVC.userEmail = peerEmail;
        contactDetailsVC.userName = peerName;
        contactDetailsVC.userHandle = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification {
     //Display custom menu actions for cells.
    UIMenuController *menu = [notification object];
    menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Edit" action:@selector(editAction:megaMessage:)] ];
    
    [super didReceiveMenuWillShowNotification:notification];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    // [JSQSystemSoundPlayer jsq_playMessageSentSound];

    //TODO: Add the message here instead in the callback. Problem we have not the index of the message
//    MEGAMessage *message = [[MEGAMessage alloc] initWithSenderId:senderId
//                                              senderDisplayName:senderDisplayName
//                                                           date:date
//                                                           text:text];
    if (!self.editMessage) {
        [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:self.chatRoom.chatId message:text];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] editMessageForChat:self.chatRoom.chatId messageId:self.editMessage.messageId message:text];
    }
    self.editMessage = nil;
//    [self.indexesMessages addObject:message];
    
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Media messages", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Send photo", nil), NSLocalizedString(@"Send location", nil), NSLocalizedString(@"Send video", nil), NSLocalizedString(@"Send audio", nil), nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.inputToolbar.contentView.textView becomeFirstResponder];
        return;
    }
}

#pragma mark - JSQMessages CollectionView DataSource

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%llu", [[[MEGASdkManager sharedMEGASdk] myUser] handle]];
}

- (NSString *)senderDisplayName {
    return [[[MEGASdkManager sharedMEGASdk] myUser] email];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    return megaMessage;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.indexesMessages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    BOOL showDayMonthYear = NO;
    if (indexPath.item == 0) {
        showDayMonthYear = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:(indexPath.item -1)]];
        showDayMonthYear = [self showDateBetweenMessage:message previousMessage:previousMessage];
    }
    
    if (showDayMonthYear) {
        NSString *dateString = [[JSQMessagesTimestampFormatter sharedFormatter] relativeDateForDate:message.date];
        NSAttributedString *dateAttributedString = [[NSAttributedString alloc] initWithString:dateString attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
        return dateAttributedString;
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    BOOL showHour = NO;
    if (indexPath.item == 0) {
        showHour = YES;
    } else if (indexPath.item - 1 > 0) {
        showHour = [self showHourForMessage:message withIndexPath:indexPath];
    }
    
    if (showHour) {
        NSString *hour = [[JSQMessagesTimestampFormatter sharedFormatter] timeForDate:message.date];
        return [[NSAttributedString alloc] initWithString:hour attributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:9.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]}];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (megaMessage.isEdited) {
        NSString *editedString = AMLocalizedString(@"edited", @"A log message in a chat to indicate that the message has been edited by the user.");
        NSAttributedString *dateAttributedString = [[NSAttributedString alloc] initWithString:editedString attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:9.0f], NSForegroundColorAttributeName:[UIColor mnz_blue2BA6DE]}];
        return dateAttributedString;
    }
    
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.indexesMessages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if (!megaMessage.isMediaMessage) {
        cell.textView.selectable = NO;
        cell.textView.userInteractionEnabled = NO;
        cell.textView.textColor = [UIColor mnz_black333333];
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    cell.accessoryButton.hidden = YES;
    return cell;
}

#pragma mark - UICollectionViewDelegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if (action == @selector(copy:)) {
        return YES;
    }
    
    if (!megaMessage.isEditable) {
        return NO;
    }
    
    if (![megaMessage.senderId isEqualToString:self.senderId]) {
        return NO;
    }
    if (action == @selector(editAction:megaMessage:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (action == @selector(editAction:megaMessage:)) {
        [self editAction:sender megaMessage:megaMessage];
        return;
    }
    
    if (action == @selector(delete:)) {
        [[MEGASdkManager sharedMEGAChatSdk] deleteMessageForChat:self.chatRoom.chatId messageId:megaMessage.messageId];
    }
    
    if (action != @selector(delete:)) {
        [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}

- (void)editAction:(id)sender megaMessage:(MEGAMessage *)megaMessage; {
    [self.inputToolbar.contentView.textView becomeFirstResponder];
    self.inputToolbar.contentView.textView.text = megaMessage.text;
    self.editMessage = megaMessage;
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    BOOL showDayMonthYear = NO;
    if (indexPath.item == 0) {
        showDayMonthYear = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:(indexPath.item - 1)]];
        showDayMonthYear = [self showDateBetweenMessage:message previousMessage:previousMessage];
    }
    
    if (showDayMonthYear) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    BOOL showHour = NO;
    if (indexPath.item == 0) {
        showHour = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
        showHour = [self showHourForMessage:message withIndexPath:indexPath];
    }
    
    if (showHour) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (megaMessage.isEdited) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
    NSLog(@"Load earlier messages!");
    [self loadMessages];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation {
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender {
    if ([UIPasteboard generalPasteboard].image) {
        return NO;
    }
    return YES;
}

#pragma mark - JSQMessagesViewAccessoryDelegate methods

- (void)messageView:(JSQMessagesCollectionView *)view didTapAccessoryButtonAtIndexPath:(NSIndexPath *)path {
    NSLog(@"Tapped accessory button!");
}



#pragma mark - MEGAChatRoomDelegate

- (void)onMessageReceived:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageReceived %@", message);
    MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message];
    
    [self.indexesMessages addObject:[NSNumber numberWithInteger:message.messageIndex]];
    [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
    [self finishReceivingMessage];
}

- (void)onMessageLoaded:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageLoaded %@", message);
    
    if (message && message.type != MEGAChatMessageTypeTruncate) {
        MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message];        
        [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
        [self.indexesMessages insertObject:[NSNumber numberWithInteger:message.messageIndex] atIndex:0];
    } else {
        [self.collectionView reloadData];
        [self scrollToBottomAnimated:YES];
    }
}

- (void)onMessageUpdate:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageUpdate %@", message);
    
    MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message];
    [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
    
    if ([message hasChangedForType:MEGAChatMessageChangeTypeStatus]) {
        MEGALogInfo(@"Message update: change status");
        if (message.status == MEGAChatMessageStatusServerReceived) {
            [self.indexesMessages addObject:[NSNumber numberWithInteger:message.messageIndex]];
            [self finishSendingMessageAnimated:YES];
        }
    }
    
    if ([message hasChangedForType:MEGAChatMessageChangeTypeContent]) {
        if (message.isDeleted) {
            MEGALogInfo(@"Message update (delete): change content.");
            [self.collectionView reloadData];
        } else if (message.isEdited) {
            MEGALogInfo(@"Message update (edit): change content: %@", message.content);
            [self.collectionView reloadData];
            [self scrollToBottomAnimated:YES];
        }
    }
    
}

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    NSLog(@"onChatRoomUpdate %@", chat);
}

@end
