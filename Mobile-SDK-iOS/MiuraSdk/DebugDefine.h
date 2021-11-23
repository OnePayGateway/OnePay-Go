//#Alternatives to NSLog

//•    ALog () will display the standard NSLog but containing function and line number.
//•    DLog () will output like NSLog only when the DEBUG variable is set
//•    ULog () will show the UIAlertView only when the DEBUG variable is set

#define ALog(fmt, ...) NSLog((@"%s %s [Line %d] " fmt), __FILE__, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#if DEBUG
#define DLog(format,...) NSLog([NSString stringWithFormat:@"[MiuraSDK] %@", [NSString stringWithFormat:format, ##__VA_ARGS__]], nil)
#else
#define DLog(format,...)
#endif

#ifdef DEBUG
#   define ULog (fmt, ...)  { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%s\n [Line %d] ", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:fmt, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil]; [alert show]; }
#else
#   define ULog(...)
#endif

#if DEBUG
#define DCLog(...) NSLog(@"%@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define DCLog(format,...)
#endif
