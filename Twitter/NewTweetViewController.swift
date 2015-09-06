//
//  ViewController.swift
//  Twitter
//
//  Created by Kromyko Cruzado on 9/6/15.
//  Copyright (c) 2015 Kromyko Cruzado. All rights reserved.
//

import UIKit
import Accounts
import Social

protocol NewTweetDelegate {
    
    func postTweet()
}

class NewTweetViewController: UIViewController {
    

    var twitterAccount: ACAccount?
    
    var tempProfilePicture : UIImage?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    
    @IBOutlet weak var tweetContent: UITextView!
    var delegate: NewTweetDelegate?
    
    override func viewDidLoad() {
       super.viewDidLoad()
        activityIndicator.hidden = true
        self.username.text = self.twitterAccount?.username
        self.profilePicture.image = tempProfilePicture
    
    // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func postNewTweet(sender: UIBarButtonItem) {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, URL: requestURL, parameters: ["status": self.tweetContent.text])
        // println()
        request.account = self.twitterAccount!
        request.performRequestWithHandler({
            (responseData, urlResponse, error) -> Void in
            var image: UIImage?
            if urlResponse.statusCode == 200 {
                println("status posted")
                self.delegate?.postTweet()
                
            }
            else {
                println(error)
                println(urlResponse)
            }
            dispatch_async(dispatch_get_main_queue(), {
               self.activityIndicator.stopAnimating()
                self.activityIndicator.hidden = true
                self.dismissViewControllerAnimated(true, completion: nil)
              
            })
        })
    }
    
    @IBAction func dismissNewTweet(sender: UIBarButtonItem) {
    }
    

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

