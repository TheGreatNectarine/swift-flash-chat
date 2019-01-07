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
    }
}
