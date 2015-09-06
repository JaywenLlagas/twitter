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

class TwitterTVC : UIViewController, NewTweetDelegate {

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
    
 
    
    func postTweet() {
        retrieveTweets()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        composeTweet.enabled = false
        //self.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        accountStore = ACAccountStore()
        var accountType : ACAccountType = accountStore!.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore?.requestAccessToAccountsWithType(accountType, options: nil, completion: {granted, error in
            if granted {
                if let tempAccounts = self.accountStore?.accountsWithAccountType(accountType) {
                    if tempAccounts.count > 0 {
                        self.twitterAccount = tempAccounts[0] as? ACAccount
                    }
                }
                if self.twitterAccount == nil {
                    let alert = UIAlertController(title: "No twitter account", message: "Please set up a twitter account first", preferredStyle: UIAlertControllerStyle.Alert)
                    let okayAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil)
                    alert.addAction(okayAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        println("dispatch username")
                        self.navigationItem.title = self.twitterAccount!.username
                    })
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
    
    func retrieveProfileDetails() {
        println("profile details 1")
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/users/show.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, URL: requestURL, parameters: ["screen_name": self.twitterAccount!.username])
        // println()
        request.account = self.twitterAccount!
        println("profile details 2")
        request.performRequestWithHandler({
            (responseData, urlResponse, error) -> Void in
            println("profile details 3")
            var image: UIImage?
            var tempFollowers: Int?
            var tempFollowing: Int?
            if urlResponse.statusCode == 200 {
                var jsonParserError: NSError?
                let results = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &jsonParserError) as! NSDictionary
                //println(results)
                var imageURL = (results.objectForKey("profile_image_url") as! String).stringByReplacingOccurrencesOfString("normal", withString: "bigger", options: nil, range: nil)
                
                
                let url = NSURL(string: imageURL)
                let imageData = NSData(contentsOfURL: url!)
                image = UIImage(data: imageData!)!
                tempFollowers = results.objectForKey("followers_count") as? Int
                tempFollowing = results.objectForKey("friends_count") as? Int
                println("profile details 4")
                
            }
            println("profile details 5")
            dispatch_async(dispatch_get_main_queue(), {
                println("dispatch profile")
                self.followers.text = String(tempFollowers!)
                self.following.text = String(tempFollowing!)
                self.profilePicture.image = image
                println(self.profilePicture.image)
                self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2;
                self.profilePicture.clipsToBounds = true;
                self.profilePicture.layer.borderWidth = 5;
                self.profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
                self.composeTweet.enabled = true
               println("yeah")
            })
            println("profile details 6")
        })
        println("profile details 7")
    }
    
    func retrieveProfileBanner() {
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/users/profile_banner.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, URL: requestURL, parameters: ["screen_name": self.twitterAccount!.username])
       // println()
        request.account = self.twitterAccount!
        request.performRequestWithHandler({
            (responseData, urlResponse, error) -> Void in
            var image: UIImage?
            if urlResponse.statusCode == 200 {
                var jsonParserError: NSError?
                let results = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &jsonParserError) as! NSDictionary
                let imageURL = results.objectForKey("sizes")?.objectForKey("mobile_retina")?.objectForKey("url") as! String
                let url = NSURL(string: imageURL)
                let imageData = NSData(contentsOfURL: url!)
                image = UIImage(data: imageData!)!
                
                
            }
            dispatch_async(dispatch_get_main_queue(), {
                println("dispatch banner")
                self.bannerImage.image = image
            })
        })
    }
    
    func retrieveTweets() {
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, URL: requestURL, parameters: nil)
        request.account = self.twitterAccount!
        request.performRequestWithHandler({
            (responseData, urlResponse, error) -> Void in
            if urlResponse.statusCode == 200 {
                var jsonParserError: NSError?
                self.tweets = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &jsonParserError) as? NSMutableArray
                //println(self.tweets)
            }
            else {
                println("limit reached error")
                //println(urlResponse)
            }
            dispatch_async(dispatch_get_main_queue(), {
                println("dispatch tweets")
                self.tableView.reloadData()
            })
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if let totalTweets = self.tweets?.count {
            return totalTweets
        }
        return 0
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("feedIdentifier", forIndexPath: indexPath) as! FeedTableViewCell
        
        let tweetData = self.tweets?.objectAtIndex(indexPath.row) as! NSDictionary
        let userData = tweetData.objectForKey("user") as! NSDictionary

        cell.username.text = userData.objectForKey("name") as? String
        cell.tweetDetails.text = tweetData.objectForKey("text") as? String
       
        let imageURL = userData.objectForKey("profile_image_url") as? String
        //println(imageCache)
        
        if let image = imageCache?.objectForKey(imageURL!) as? UIImage {
            cell.profilePicture.image = image
            //println("cache")
        } else {
            
            queue?.addOperationWithBlock({
                let url = NSURL(string: imageURL!)
                let imageData = NSData(contentsOfURL: url!)
                let image = UIImage(data: imageData!)
                
                if let downloadedImage = image {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        //let cell = tableView.cellForRowAtIndexPath(indexPath) as! FeedTableViewCell
                        cell.profilePicture.image = downloadedImage
                        self.imageCache?.setObject(downloadedImage, forKey: imageURL!)
                       
                    })
                    
                }
                else {
                    //println("image is nil")
                }
                
                
            })
            
        }
        

        return cell
    }
    


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "newTweetIdentifier" {
            if let vc = segue.destinationViewController as? NewTweetViewController {
                vc.delegate = self
                vc.twitterAccount = self.twitterAccount
                vc.tempProfilePicture = self.profilePicture.image
            }
        }
        
    }


}
