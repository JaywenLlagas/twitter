//
//  TwitterTVC.swift
//  Twitter
//
//  Created by Kromyko Cruzado on 9/6/15.
//  Copyright (c) 2015 Kromyko Cruzado. All rights reserved.
//

import UIKit
import Accounts
import Social

class TwitterTVC : UIViewController {

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var accountStore: ACAccountStore?
    var twitterAccount: ACAccount?
    var tweets: NSMutableArray?
    var imageCache: NSCache?
    var queue: NSOperationQueue?
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var following: UILabel!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var composeTweet: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        composeTweet.enabled = false
        accountStore = ACAccountStore()
        
        var accountType : ACAccountType =  accountStore!.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        

        accountStore?.requestAccessToAccountsWithType(accountType, options: nil, completion : {(granted, error) -> Void in
            if granted {
                
                if let tempAccounts = self.accountStore?.accountsWithAccountType(accountType) {
                    if tempAccounts.count > 0 {
                        self.twitterAccount = tempAccounts[0] as? ACAccount
                    }
                }
                
                if self.twitterAccount == nil {
                    let alert = UIAlertController(
                        title: "No twitter account",
                        message: "Please set up a twitter account first",
                        preferredStyle: UIAlertControllerStyle.Alert
                    )
                    let okayAction = UIAlertAction(title: "okay", style: UIAlertActionStyle.Cancel, handler: nil)
                    alert.addAction(okayAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    dispatch_async(dispatch_get_main_queue(), {self.navigationItem.title = self.twitterAccount!.username})
                    
                    self.imageCache = NSCache()
                    self.queue = NSOperationQueue()
                    self.queue?.maxConcurrentOperationCount = 4
                    self.retrieveProfileBanner()
                    self.retrieveProfileDetails()
                    self.retrieveTweets()
                }
            }
        })
        
    }
    
    func retrieveTweets() {
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.GET, URL:requestURL,parameters:nil
        )
        request.account = self.twitterAccount!
        
        request.performRequestWithHandler({(responseData, urlResponse, error) -> Void in
            if urlResponse.statusCode == 200 {
                var jsonParserError: NSError?
                self.tweets = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &jsonParserError) as? NSMutableArray
            } else {
                println("limit reached error")
            }
            dispatch_async(dispatch_get_main_queue(), {self.tableView.reloadData()}
            )
        })
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("feedIdentifier", forIndexPath: indexPath) as! FeedTableViewCell
        
        let tweetData = self.tweets?.objectAtIndex(indexPath.row) as! NSDictionary
        let userData = tweetData.objectForKey("user") as! NSDictionary
        
        cell.username.text = userData.objectForKey("name") as? String
        cell.tweetDetails.text = tweetData.objectForKey("text") as? String
        
        let imageURL = userData.objectForKey("profile_image_url") as? String
        
        if let image = imageCache?.objectForKey(imageURL!) as? UIImage {
            cell.profilePicture.image = image
        } else {
            
            queue?.addOperationWithBlock({
                let url = NSURL(string: imageURL!)
                let imageData = NSData(contentsOfURL: url!)
                let image = UIImage(data: imageData!)
                
                if let downloadedImage = image {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        cell.profilePicture.image = downloadedImage
                        self.imageCache?.setObject(downloadedImage, forKey: imageURL!)
                    })
                }
            })
        }
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let totalTweets = self.tweets?.count {
            return totalTweets
        }
        return 0
    }
    
    func retrieveProfileBanner() {
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/users/profile_banner.json")
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.GET,
            URL: requestURL,
            parameters: ["screen_name": self.twitterAccount!.username]
        )
        
        request.account = self.twitterAccount!
        request.performRequestWithHandler({(responseData, urlResponse, error) -> Void in
            var image: UIImage?
            if urlResponse.statusCode == 200 {
                var jsonParserError: NSError?
                let results = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &jsonParserError) as! NSDictionary
                
                let imageURL = results.objectForKey("sizes")?.objectForKey("mobile_retina")?.objectForKey("url") as! String
                let url = NSURL(string: imageURL)
                let imageData = NSData(contentsOfURL: url!)
                image = UIImage(data: imageData!)!
            }
            dispatch_async(dispatch_get_main_queue(),
                {println("dispatch banner")
                    self.bannerImage.image = image})
        })
    }
    
    func retrieveProfileDetails() {
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/users/show.json")
        
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.GET,
            URL: requestURL,
            parameters: ["screen_name": self.twitterAccount!.username]
        )
        
        request.account = self.twitterAccount!
        
        request.performRequestWithHandler({(responseData, urlResponse, error) -> Void in
            var image: UIImage?
            var followCount : Int?
            var followerCount : Int?
            if urlResponse.statusCode == 200 {
                var jsonParserError: NSError?
                let results = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &jsonParserError) as! NSDictionary
                
                let imageURL = results.objectForKey("profile_image_url") as! String
                
                followCount = results.objectForKey("followers_count") as? Int
                followerCount = results.objectForKey("friends_count") as? Int
                let DP = imageURL.stringByReplacingOccurrencesOfString("_normal", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                let url = NSURL(string: DP)
                let imageData = NSData(contentsOfURL: url!)
                image = UIImage(data: imageData!)!
                
            }
            dispatch_async(dispatch_get_main_queue(),
                {println("dispatch banner")
                    self.profilePicture.image = image
                    self.following.text = String(followCount!)
                    self.followers.text = String(followerCount!)
            })
        })
    }
}

    