//
//  UIViewController+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 22.11.2021.
//

import UIKit.UIViewController
import UIKit.UIColor
import Combine

extension UIViewController: UIGestureRecognizerDelegate {
    var sceneDelegate: SceneDelegate? {
        for scene in UIApplication.shared.connectedScenes {
            if scene == SceneDelegate.currentScene,
               let delegate = scene.delegate as? SceneDelegate {
                return delegate
            }
        }
        return nil
    }
    
    func setCustomNavigationBackButton(with imageName: String, bag: inout Set<AnyCancellable>) {
        let backButton = UIBarButtonItem(
            image: UIImage(named: imageName)!,
            style: .plain,
            target: navigationController,
            action: nil)
        backButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).store(in: &bag)
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    func setAttributedTitle(with text: String, color: UIColor) {
        let textAttributes = [NSAttributedString.Key.foregroundColor: color]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = color
        title = text
    }
    
    func share() {
        let textToShare = "Check out Fairytales app"
        if let myWebsite = URL(string: "https://apps.apple.com/app/id") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            /// Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        } else {
            return defaultUrl
        }
    }
    /*
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    func sendEmail() {
        let recipientEmail = "app@smedia.tech"
        let subject = "Fairytales"
        let iosVersion = UIDevice.current.systemVersion
        let deviceName = UIDevice.current.modelName
        let body = "Device: \(deviceName), iOS version: \(iosVersion)\n"
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([recipientEmail])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else if let emailUrl = createEmailUrl(to: recipientEmail, subject: subject, body: body) {
            UIApplication.shared.open(emailUrl)
        }
    } */
}
