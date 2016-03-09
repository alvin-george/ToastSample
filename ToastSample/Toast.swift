//  Toast.swift

import UIKit
import ObjectiveC

enum ToastPosition {
 case Top
 case Center
 case Bottom
}

extension UIView {

 private struct ToastKeys {
  static var Timer        = "CSToastTimerKey"
  static var Duration     = "CSToastDurationKey"
  static var Position     = "CSToastPositionKey"
  static var Completion   = "CSToastCompletionKey"
  static var ActiveToast  = "CSToastActiveToastKey"
  static var ActivityView = "CSToastActivityViewKey"
  static var Queue        = "CSToastQueueKey"
 }

 private class ToastCompletionWrapper {
  var completion: ((Bool) -> Void)?

  init(_ completion: ((Bool) -> Void)?) {
   self.completion = completion
  }
 }

 private enum ToastError: ErrorType {
  case InsufficientData
 }

 private var queue: NSMutableArray {
  get {
   if let queue = objc_getAssociatedObject(self, &ToastKeys.Queue) as? NSMutableArray {
    return queue
   } else {
    let queue = NSMutableArray()
    objc_setAssociatedObject(self, &ToastKeys.Queue, queue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return queue
   }
  }
 }

 // MARK: - Make Toast Methods
 func makeToast(message: String) {
  self.makeToast(message, duration: ToastManager.shared.duration, position: ToastManager.shared.position)
 }
 func makeToast(message: String, duration: NSTimeInterval, position: ToastPosition) {
  self.makeToast(message, duration: duration, position: position, style: nil)
 }
 func makeToast(message: String, duration: NSTimeInterval, position: CGPoint) {
  self.makeToast(message, duration: duration, position: position, style: nil)
 }
 func makeToast(message: String, duration: NSTimeInterval, position: ToastPosition, style: ToastStyle?) {
  self.makeToast(message, duration: duration, position: position, title: nil, image: nil, style: style, completion: nil)
 }
 func makeToast(message: String, duration: NSTimeInterval, position: CGPoint, style: ToastStyle?) {
  self.makeToast(message, duration: duration, position: position, title: nil, image: nil, style: style, completion: nil)
 }
 func makeToast(message: String?, duration: NSTimeInterval, position: ToastPosition, title: String?, image: UIImage?, style: ToastStyle?, completion: ((didTap: Bool) -> Void)?) {
  var toastStyle = ToastManager.shared.style
  if let style = style {
   toastStyle = style
  }

  do {
   let toast = try self.toastViewForMessage(message, title: title, image: image, style: toastStyle)
   self.showToast(toast, duration: duration, position: position, completion: completion)
  } catch ToastError.InsufficientData {
   print("Error: message, title, and image are all nil")
  } catch {}
 }

 func makeToast(message: String?, duration: NSTimeInterval, position: CGPoint, title: String?, image: UIImage?, style: ToastStyle?, completion: ((didTap: Bool) -> Void)?) {
  var toastStyle = ToastManager.shared.style
  if let style = style {
   toastStyle = style
  }

  do {
   let toast = try self.toastViewForMessage(message, title: title, image: image, style: toastStyle)
   self.showToast(toast, duration: duration, position: position, completion: completion)
  } catch ToastError.InsufficientData {
   print("Error: message, title, and image cannot all be nil")
  } catch {}
 }

 // MARK: - Show Toast Methods
 func showToast(toast: UIView) {
  self.showToast(toast, duration: ToastManager.shared.duration, position: ToastManager.shared.position, completion: nil)
 }
 func showToast(toast: UIView, duration: NSTimeInterval, position: ToastPosition, completion: ((didTap: Bool) -> Void)?) {
  let point = self.centerPointForPosition(position, toast: toast)
  self.showToast(toast, duration: duration, position: point, completion: completion)
 }

 func showToast(toast: UIView, duration: NSTimeInterval, position: CGPoint, completion: ((didTap: Bool) -> Void)?) {
  objc_setAssociatedObject(toast, &ToastKeys.Completion, ToastCompletionWrapper(completion), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  if let _ = objc_getAssociatedObject(self, &ToastKeys.ActiveToast) as? UIView where ToastManager.shared.queueEnabled {
   objc_setAssociatedObject(toast, &ToastKeys.Duration, NSNumber(double: duration), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
   objc_setAssociatedObject(toast, &ToastKeys.Position, NSValue(CGPoint: position), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);

   self.queue.addObject(toast)
  } else {
   self.showToast(toast, duration: duration, position: position)
  }
 }

 // MARK: - Activity Methods
 func makeToastActivity(position: ToastPosition) {
  // sanity
  if let _ = objc_getAssociatedObject(self, &ToastKeys.ActiveToast) as? UIView {
   return
  }

  let toast = self.createToastActivityView()
  let point = self.centerPointForPosition(position, toast: toast)
  self.makeToastActivity(toast, position: point)
 }
 func makeToastActivity(position: CGPoint) {
  // sanity
  if let _ = objc_getAssociatedObject(self, &ToastKeys.ActiveToast) as? UIView {
   return
  }

  let toast = self.createToastActivityView()
  self.makeToastActivity(toast, position: position)
 }

 //Dismisses the active toast activity indicator view.
 func hideToastActivity() {
  if let toast = objc_getAssociatedObject(self, &ToastKeys.ActivityView) as? UIView {
   UIView.animateWithDuration(ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.CurveEaseIn, .BeginFromCurrentState], animations: { () -> Void in
    toast.alpha = 0.0
    }, completion: { (finished: Bool) -> Void in
     toast.removeFromSuperview()
     objc_setAssociatedObject(self, &ToastKeys.ActivityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
   })
  }
 }

 // MARK: - Private Activity Methods
 private func makeToastActivity(toast: UIView, position: CGPoint) {
  toast.alpha = 0.0
  toast.center = position

  objc_setAssociatedObject(self, &ToastKeys.ActivityView, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

  self.addSubview(toast)

  UIView.animateWithDuration(ToastManager.shared.style.fadeDuration, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
   toast.alpha = 1.0
   }, completion: nil)
 }

 private func createToastActivityView() -> UIView {
  let style = ToastManager.shared.style

  let activityView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: style.activitySize.width, height: style.activitySize.height))
  activityView.backgroundColor = style.backgroundColor
  activityView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
  activityView.layer.cornerRadius = style.cornerRadius

  if style.displayShadow {
   activityView.layer.shadowColor = style.shadowColor.CGColor
   activityView.layer.shadowOpacity = style.shadowOpacity
   activityView.layer.shadowRadius = style.shadowRadius
   activityView.layer.shadowOffset = style.shadowOffset
  }

  let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
  activityIndicatorView.center = CGPoint(x: activityView.bounds.size.width / 2.0, y: activityView.bounds.size.height / 2.0)
  activityView.addSubview(activityIndicatorView)
  activityIndicatorView.startAnimating()

  return activityView
 }

 // MARK: - Private Show/Hide Methods
 private func showToast(toast: UIView, duration: NSTimeInterval, position: CGPoint) {
  toast.center = position
  toast.alpha = 0.0

  if ToastManager.shared.tapToDismissEnabled {
   let recognizer = UITapGestureRecognizer(target: self, action: "handleToastTapped:")
   toast.addGestureRecognizer(recognizer)
   toast.userInteractionEnabled = true
   toast.exclusiveTouch = true
  }

  objc_setAssociatedObject(self, &ToastKeys.ActiveToast, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  self.addSubview(toast)

  UIView.animateWithDuration(ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in
   toast.alpha = 1.0
   }) { (Bool finished) -> Void in
    let timer = NSTimer(timeInterval: duration, target: self, selector: "toastTimerDidFinish:", userInfo: toast, repeats: false)
    NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    objc_setAssociatedObject(toast, &ToastKeys.Timer, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
 }

 private func hideToast(toast: UIView) {
  self.hideToast(toast, fromTap: false)
 }

 private func hideToast(toast: UIView, fromTap: Bool) {

  UIView.animateWithDuration(ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.CurveEaseIn, .BeginFromCurrentState], animations: { () -> Void in
   toast.alpha = 0.0
   }) { (didFinish: Bool) -> Void in
    toast.removeFromSuperview()

    objc_setAssociatedObject(self, &ToastKeys.ActiveToast, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if let wrapper = objc_getAssociatedObject(toast, &ToastKeys.Completion) as? ToastCompletionWrapper, completion = wrapper.completion {
     completion(fromTap)
    }

    if let nextToast = self.queue.firstObject as? UIView, duration = objc_getAssociatedObject(nextToast, &ToastKeys.Duration) as? NSNumber, position = objc_getAssociatedObject(nextToast, &ToastKeys.Position) as? NSValue {
     self.queue.removeObjectAtIndex(0)
     self.showToast(nextToast, duration: duration.doubleValue, position: position.CGPointValue())
    }
  }
 }

 // MARK: - Events
 func handleToastTapped(recognizer: UITapGestureRecognizer) {
  if let toast = recognizer.view, timer = objc_getAssociatedObject(toast, &ToastKeys.Timer) as? NSTimer {
   timer.invalidate()
   self.hideToast(toast, fromTap: true)
  }
 }

 func toastTimerDidFinish(timer: NSTimer) {
  if let toast = timer.userInfo as? UIView {
   self.hideToast(toast)
  }
 }

 // MARK: - Toast Construction
 func toastViewForMessage(message: String?, title: String?, image: UIImage?, style: ToastStyle) throws -> UIView {
  // sanity
  if message == nil && title == nil && image == nil {
   throw ToastError.InsufficientData
  }

  var messageLabel: UILabel?
  var titleLabel: UILabel?
  var imageView: UIImageView?

  let wrapperView = UIView()
  wrapperView.backgroundColor = style.backgroundColor
  wrapperView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
  wrapperView.layer.cornerRadius = style.cornerRadius

  if style.displayShadow {
   wrapperView.layer.shadowColor = UIColor.blackColor().CGColor
   wrapperView.layer.shadowOpacity = style.shadowOpacity
   wrapperView.layer.shadowRadius = style.shadowRadius
   wrapperView.layer.shadowOffset = style.shadowOffset
  }

  if let image = image {
   imageView = UIImageView(image: image)
   imageView?.contentMode = .ScaleAspectFit
   imageView?.frame = CGRect(x: style.horizontalPadding, y: style.verticalPadding, width: style.imageSize.width, height: style.imageSize.height)
  }

  var imageRect = CGRectZero

  if let imageView = imageView {
   imageRect.origin.x = style.horizontalPadding
   imageRect.origin.y = style.verticalPadding
   imageRect.size.width = imageView.bounds.size.width
   imageRect.size.height = imageView.bounds.size.height
  }

  if let title = title {
   titleLabel = UILabel()
   titleLabel?.numberOfLines = style.titleNumberOfLines
   titleLabel?.font = style.titleFont
   titleLabel?.textAlignment = style.titleAlignment
   titleLabel?.lineBreakMode = .ByTruncatingTail
   titleLabel?.textColor = style.titleColor
   titleLabel?.backgroundColor = UIColor.clearColor();
   titleLabel?.text = title;

   let maxTitleSize = CGSize(width: (self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, height: self.bounds.size.height * style.maxHeightPercentage)
   let titleSize = titleLabel?.sizeThatFits(maxTitleSize)
   if let titleSize = titleSize {
    titleLabel?.frame = CGRect(x: 0.0, y: 0.0, width: titleSize.width, height: titleSize.height)
   }
  }

  if let message = message {
   messageLabel = UILabel()
   messageLabel?.text = message
   messageLabel?.numberOfLines = style.messageNumberOfLines
   messageLabel?.font = style.messageFont
   messageLabel?.textAlignment = style.messageAlignment
   messageLabel?.lineBreakMode = .ByTruncatingTail;
   messageLabel?.textColor = style.messageColor
   messageLabel?.backgroundColor = UIColor.clearColor()

   let maxMessageSize = CGSize(width: (self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, height: self.bounds.size.height * style.maxHeightPercentage)
   let messageSize = messageLabel?.sizeThatFits(maxMessageSize)
   if let messageSize = messageSize {
    messageLabel?.frame = CGRect(x: 0.0, y: 0.0, width: messageSize.width, height: messageSize.height)
   }
  }

  var titleRect = CGRectZero

  if let titleLabel = titleLabel {
   titleRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding
   titleRect.origin.y = style.verticalPadding
   titleRect.size.width = titleLabel.bounds.size.width
   titleRect.size.height = titleLabel.bounds.size.height
  }

  var messageRect = CGRectZero

  if let messageLabel = messageLabel {
   messageRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding
   messageRect.origin.y = titleRect.origin.y + titleRect.size.height + style.verticalPadding
   messageRect.size.width = messageLabel.bounds.size.width
   messageRect.size.height = messageLabel.bounds.size.height
  }

  let longerWidth = max(titleRect.size.width, messageRect.size.width)
  let longerX = max(titleRect.origin.x, messageRect.origin.x)
  let wrapperWidth = max((imageRect.size.width + (style.horizontalPadding * 2.0)), (longerX + longerWidth + style.horizontalPadding))
  let wrapperHeight = max((messageRect.origin.y + messageRect.size.height + style.verticalPadding), (imageRect.size.height + (style.verticalPadding * 2.0)))

  wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)

  if let titleLabel = titleLabel {
   titleLabel.frame = titleRect
   wrapperView.addSubview(titleLabel)
  }

  if let messageLabel = messageLabel {
   messageLabel.frame = messageRect
   wrapperView.addSubview(messageLabel)
  }

  if let imageView = imageView {
   wrapperView.addSubview(imageView)
  }

  return wrapperView
 }

 // MARK: - Helpers
 private func centerPointForPosition(position: ToastPosition, toast: UIView) -> CGPoint {
  let padding: CGFloat = ToastManager.shared.style.verticalPadding

  switch(position) {
  case .Top:
   return CGPoint(x: self.bounds.size.width / 2.0, y: (toast.frame.size.height / 2.0) + padding)
  case .Center:
   return CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
  case .Bottom:
   return CGPoint(x: self.bounds.size.width / 2.0, y: (self.bounds.size.height - (toast.frame.size.height / 2.0)) - padding)
  }
 }
}

// MARK: - Toast Style
struct ToastStyle {

 var backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
 var titleColor = UIColor.whiteColor()
 var messageColor = UIColor.whiteColor()
 var maxWidthPercentage: CGFloat = 0.8 {
  didSet {
   maxWidthPercentage = max(min(maxWidthPercentage, 1.0), 0.0)
  }
 }


 var maxHeightPercentage: CGFloat = 0.8 {
  didSet {
   maxHeightPercentage = max(min(maxHeightPercentage, 1.0), 0.0)
  }
 }

 var horizontalPadding: CGFloat = 10.0
 var verticalPadding: CGFloat = 10.0
 var cornerRadius: CGFloat = 10.0;
 var titleFont = UIFont.boldSystemFontOfSize(16.0)
 var messageFont = UIFont.systemFontOfSize(16.0)
 var titleAlignment = NSTextAlignment.Left
 var messageAlignment = NSTextAlignment.Left
 var titleNumberOfLines = 0;
 var messageNumberOfLines = 0;
 var displayShadow = false;
 var shadowColor = UIColor.blackColor()
 var shadowOpacity: Float = 0.8 {
  didSet {
   shadowOpacity = max(min(shadowOpacity, 1.0), 0.0)
  }
 }

 var shadowRadius: CGFloat = 6.0
 var shadowOffset = CGSize(width: 4.0, height: 4.0)
 var imageSize = CGSize(width: 80.0, height: 80.0)
 var activitySize = CGSize(width: 100.0, height: 100.0)
 var fadeDuration: NSTimeInterval = 0.2

}

// MARK: - Toast Manager
class ToastManager {

 static let shared = ToastManager()
 var style = ToastStyle()
 var tapToDismissEnabled = true
 var queueEnabled = true
 var duration: NSTimeInterval = 3.0
 var position = ToastPosition.Bottom
 
}