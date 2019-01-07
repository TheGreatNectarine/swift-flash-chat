import UIKit
import Firebase
import ChameleonFramework
import SVProgressHUD

//MARK: - TableView Delegate and Datasource methods
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
		cell.sender = messages[indexPath.row].sender
		cell.message = messages[indexPath.row].body
		cell.avatarImageView.image = UIImage(named: "egg")

		if cell.sender == Auth.auth().currentUser?.email {
			cell.avatarImageView.backgroundColor = UIColor.flatMint()
			cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
		} else {
			cell.avatarImageView.backgroundColor = UIColor.flatWatermelon()
			cell.messageBackground.backgroundColor = UIColor.flatGray()
		}
		return cell
	}

	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
			self.messages.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .automatic)
			//TODO: Delete messages
		}
		delete.backgroundColor = .flatRed()
		let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
			print("edit")
			//TODO: Edit message
		}
		edit.backgroundColor = .flatYellow()
		return [delete, edit]
	}
}

//MARK: - UITextField related methods
extension ChatViewController: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textFieldDidChange(textField)
	}

	@objc func keyboardWillChange(_ notification: Notification) {
		guard let keyboard = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }

		let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
		var keyboardHeight = keyboard.cgRectValue.height
		if #available(iOS 11.0, *) {
			keyboardHeight -= view.safeAreaInsets.bottom
		}

		UIView.animate(withDuration: duration) {
			self.heightConstraint.constant = 50
			if notification.name == .UIKeyboardWillShow || notification.name == .UIKeyboardWillChangeFrame {
				self.heightConstraint.constant += keyboardHeight
			}
			self.view.layoutIfNeeded()
		}
	}

	@objc func textFieldWillEndEditing() {
		messageTextfield.endEditing(true)
	}

	@objc func textFieldDidChange(_ textField: UITextField) {
		let text = textField.text!
		if text.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
			disableSendButton()
		} else {
			enableSendButton()
		}
	}
}

class ChatViewController: UIViewController {

	//MARK: - IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
	@IBOutlet weak var inputContainer: UIView!

	//MARK: - Instance variables
	var messages = [Message]()
	var cachedMessage = ""

	//MARK: - View Controller lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.hidesBackButton = true

        messageTableView.delegate = self
		messageTableView.dataSource = self
		messageTextfield.delegate = self

		messageTableView.separatorStyle = .none
		disableSendButton()

		addKeyboardObservers()
		addMessageTextFieldChangeListeners()
		addMessageViewGestures()

		configureTableView()
        retrieveMessages()
    }

	//MARK: - IBAction methods
	@IBAction func logOutPressed(_ sender: AnyObject) {
		do {
			try Auth.auth().signOut()
			navigationController?.popToRootViewController(animated: true)
		} catch {
			print("error signing out")
		}
	}

	@IBAction func sendPressed(_ sender: AnyObject) {
		sendMessage()
	}

	@IBAction func textFieldPrimaryActionTriggered(_ sender: Any) {
		sendMessage()
	}

	//MARK: - Primary setting methods
	func addKeyboardObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillHide, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillChangeFrame, object: nil)
	}

	func addMessageViewGestures() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textFieldWillEndEditing))
		messageTableView.addGestureRecognizer(tapGesture)
		messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
	}

	func addMessageTextFieldChangeListeners() {
		messageTextfield.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		messageTextfield.addTarget(self, action: #selector(textFieldDidChange), for: .editingDidBegin)
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
	}
    
    //MARK: - Send & Recieve from Firebase
	func sendMessage() {
		let messagesDB = Database.database().reference().child("Messages")
		let body = messageTextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
		if body.count > 0 {
			let msg = ["Sender": Auth.auth().currentUser?.email,
					   "MessageBody": body]
			cachedMessage = body
			messageTextfield.text = ""
			disableSendButton()
			messagesDB.childByAutoId().setValue(msg) {
				(error, ref) in
				if let error = error {
					print(error)
					self.messageTextfield.text = self.cachedMessage
					self.enableSendButton()
				} else {
					print("message stored")
				}
			}
		}
	}

	func retrieveMessages() {
		SVProgressHUD.show()
		let messageDB = Database.database().reference().child("Messages")
		messageDB.observe(.childAdded) {
			snapshot in
			let snapshotVal = snapshot.value as! [String: String]
			let text = snapshotVal["MessageBody"]!
			let sender = snapshotVal["Sender"]!
			print(text, sender)
			self.messages.append(Message(sender: sender, body: text))
			self.configureTableView()
			self.messageTableView.reloadData()
			SVProgressHUD.dismiss()
			self.scrollToBottom()
		}
	}

	//MARK: - Cosmetic methods
	func configureTableView() {
		messageTableView.rowHeight = UITableViewAutomaticDimension
		messageTableView.estimatedRowHeight = 100
	}

	func scrollToBottom() {
		let indexPath = IndexPath(row: self.messages.count-1, section: 0)
		self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
	}

	func enableSendButton() {
		sendButton.isEnabled = true
		sendButton.alpha = 1.0
	}

	func disableSendButton() {
		sendButton.isEnabled = false
		sendButton.alpha = 0.5
	}
}
