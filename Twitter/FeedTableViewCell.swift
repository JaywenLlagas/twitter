//
//  FeedTableViewCell.swift
//  Twitter
//
//  Created by Kromyko Cruzado on 9/6/15.
//  Copyright (c) 2015 Kromyko Cruzado. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var tweetDetails: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
