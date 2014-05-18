#import "LGReactiveBridgeViewController.h"
#import "WebViewJavascriptBridge.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface LGReactiveBridgeViewController ()
@property WebViewJavascriptBridge* bridge;
@property BOOL showWebForm;
@property BOOL showNativeForm;
@end

@implementation LGReactiveBridgeViewController

- (id)initWithSettings:(NSDictionary *)settings {
    self = [super init];
    if (self) {
        self.title = [settings valueForKey:@"title"];
        _showWebForm = [[settings valueForKey:@"showWebForm"] boolValue];
        _showNativeForm = [[settings valueForKey:@"showNativeForm"] boolValue];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (_bridge) { return; }

    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.view.bounds];

    CGRect cgRect = CGRectZero;
    cgRect.origin.y = 50;
    if([self showWebForm]) {
        cgRect.size.height = self.view.bounds.size.height/2;
        cgRect.size.width = self.view.bounds.size.width;
    }

    webView.frame = cgRect;

    [webView setScalesPageToFit:YES];
    [self.view addSubview:webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        responseCallback(@"Response for message from ObjC");
    }];

    if ([self showNativeForm]) {
        [self renderForm:webView x: [self showWebForm] ? 150 : 0];
    }

    [self loadExamplePage:webView];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");
}

- (IBAction)textFieldFinished:(id)sender
{
    // [sender resignFirstResponder];
}

- (void)renderForm:(UIWebView*)webView x:(int)x {



    UIView *formView = [[UIView alloc] initWithFrame:CGRectMake(30, x + 70, 220, 135)];
    formView.backgroundColor = [UIColor colorWithRed:50.0/255.0f green:54.0/255.0f blue:83.0/255.0f alpha:1];
    formView.layer.cornerRadius = 15;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Native Reactive Form";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [formView addSubview:titleLabel];
    titleLabel.frame = CGRectMake(20, 10, 150, 25);

    UITextField *userNameField = [self addField:formView withRect:CGRectMake(20, 40, 135, 20) placeholder:@"username"];
    UITextField *fullNameField = [self addField:formView withRect:CGRectMake(20, 70, 135, 20) placeholder:@"Full Name"];

    [self addImage:formView withRect:CGRectMake(180, -22, 80, 80) imagePath:@"bacon.png" ];

    UILabel *availabilityLabel = [[UILabel alloc] init];
    availabilityLabel.text = @" Username is unavailable";
    availabilityLabel.textColor = [UIColor whiteColor];
    availabilityLabel.backgroundColor = [UIColor redColor];
    availabilityLabel.layer.cornerRadius = 5;
    availabilityLabel.font = [UIFont italicSystemFontOfSize:11];
    [formView addSubview:availabilityLabel];
    availabilityLabel.frame = CGRectMake(160, 35, 150, 25);

    UIButton *registerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [registerButton setTitle:@"Get Some!" forState:UIControlStateNormal];
    registerButton.backgroundColor = [UIColor grayColor];
    [registerButton setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];
    [registerButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    registerButton.layer.cornerRadius = 6;
    registerButton.titleLabel.font = [UIFont systemFontOfSize:12];
    registerButton.enabled = NO;
    [registerButton addTarget:self action:@selector(register:) forControlEvents:UIControlEventTouchUpInside];
    [formView addSubview:registerButton];
    registerButton.frame = CGRectMake(145, 100, 67, 20);

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [formView addSubview:activityIndicator];
    activityIndicator.frame = CGRectMake(160, 42, 15, 15);

    UIActivityIndicatorView *registrationIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [formView addSubview:registrationIndicator];
    registrationIndicator.frame = CGRectMake(120, 105, 15, 15);


    [userNameField.rac_textSignal subscribeNext:^(NSString * name) {
        [[self bridge] callHandler:@"usernameHandler" data:name];
    }];

    [fullNameField.rac_textSignal subscribeNext:^(NSString * name) {
        [[self bridge] callHandler:@"fullnameHandler" data:name];
    }];

    [[self bridge] registerHandler:@"fullNameEnabled" handler:^(id data, WVJBResponseCallback responseCallback) {
        BOOL b = [data boolValue];
        [fullNameField setEnabled:b];
        fullNameField.backgroundColor = b ? [UIColor whiteColor] : [UIColor grayColor];
    }];

    [[self bridge] registerHandler:@"registerButtonEnabled" handler:^(id data, WVJBResponseCallback responseCallback) {
        BOOL b = [data boolValue];
        [registerButton setEnabled:b];
        registerButton.backgroundColor = b ? [UIColor yellowColor] : [UIColor grayColor];
    }];

    [[self bridge] registerHandler:@"availabilityPending" handler:^(id data, WVJBResponseCallback responseCallback) {
        BOOL b = [data boolValue];
        b ? [activityIndicator startAnimating] : [activityIndicator stopAnimating];
    }];

    [[self bridge] registerHandler:@"unavailableLabelShowing" handler:^(id data, WVJBResponseCallback responseCallback) {
        BOOL b = [data boolValue];
        availabilityLabel.hidden = b;
    }];

    [[self bridge] registerHandler:@"registrationPending" handler:^(id data, WVJBResponseCallback responseCallback) {
        BOOL b = [data boolValue];
        b ? [registrationIndicator startAnimating] : [registrationIndicator stopAnimating];
    }];

    [[self bridge] registerHandler:@"reset" handler:^(id data, WVJBResponseCallback responseCallback) {
        [userNameField setText:@""];
        [fullNameField setText:@""];
    }];

    [self.view insertSubview:formView aboveSubview:webView];
}

- (void)addImage:(UIView *)inView withRect:(CGRect)cgRect imagePath:(NSString *)path {
    UIImage *img = [UIImage imageNamed:path];
    UIImageView *starImgView = [[UIImageView alloc] initWithFrame:cgRect];

    starImgView.image = img;
    [inView addSubview:starImgView];
}

- (UITextField *)addField:(UIView *)inView withRect:(CGRect)cgRect placeholder:(NSString *) placeholder{
    UITextField *field = [[UITextField alloc] initWithFrame:cgRect];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.font = [UIFont systemFontOfSize:15];
    field.placeholder = placeholder;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.keyboardType = UIKeyboardTypeDefault;
    field.returnKeyType = UIReturnKeyDone;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [field addTarget:self
              action:@selector(textFieldFinished:)
    forControlEvents:UIControlEventEditingDidEndOnExit];
    field.delegate = self;
    [inView addSubview:field];
    return field;
}

- (void)register:(id)sender {
    id data = @{};
    [_bridge callHandler:@"registerHandler" data:data responseCallback:^(id response) {
        NSLog(@"registerHandler responded: %@", response);
    }];
}

- (void)loadExamplePage:(UIWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"www"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}
@end
