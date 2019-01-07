//
//  CustomMessageCell.swift
//  Flash Chat
//
//  Created by Angela Yu on 30/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit

class CustomMessageCell: UITableViewCell {
    @IBOutlet var messageBackground: UIView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var messageBody: UILabel!
    @IBOutlet var senderUsername: UILabel!

	var message: String? {
		didSet {
			self.messageBody.text = message
		}
	}

	var sender: String? {
		didSet {
			self.senderUsername.text = sender
		}
	}
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code goes here
    }
}
