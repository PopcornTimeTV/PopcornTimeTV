

import UIKit
let textView = UITextView()
var timer:NSTimer!
extension UIAlertController{
    
    convenience init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle! ,withTextView: Bool!) {
        self.init(title: title, message:"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Close", style: .Default, handler: nil)
        saveAction.enabled = true
        
        view.addObserver(self, forKeyPath: "bounds", options: NSKeyValueObservingOptions.New, context: nil)
        
        if(withTextView == true){
            textView.text = message
            textView.backgroundColor = UIColor.clearColor()
            self.view.addSubview(textView)
            textView.textColor = UIColor.whiteColor()
            textView.font = UIFont.systemFontOfSize(25)
        }
        
        self.addAction(saveAction)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.08, target: self, selector: #selector(self.scrollRangeToVisible), userInfo: nil, repeats: true)
        

    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "bounds"{
            if let rect = (change?[NSKeyValueChangeNewKey] as? NSValue)?.CGRectValue(){
                let margin:CGFloat = 14.0
                textView.frame = CGRectMake(rect.origin.x + margin, rect.origin.y + margin+50, CGRectGetWidth(rect) - 2*margin, CGRectGetHeight(rect) / 2)
                textView.bounds = CGRectMake(rect.origin.x + margin, rect.origin.y + margin, CGRectGetWidth(rect) - 2*margin, CGRectGetHeight(rect) / 2)
            }
        }
    }
    
    public func scrollRangeToVisible(){
        
        var scrollPoint = textView.contentOffset; // initial and after update
        //print("%.2f %.2f",scrollPoint.x,scrollPoint.y);
        scrollPoint = CGPointMake(scrollPoint.x, scrollPoint.y + 15); // makes scroll
        textView.setContentOffset(scrollPoint, animated:true);
        if(scrollPoint.y >= textView.contentSize.height){
            scrollPoint = CGPointMake(scrollPoint.x, 0); // makes scroll
            textView.setContentOffset(scrollPoint, animated:false);
        }
        //NSLog(@"%f %f",textView.contentSize.width , textView.contentSize.height);

        
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if(timer != nil){timer.invalidate()}
    }
}