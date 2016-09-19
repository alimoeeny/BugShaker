//
//  BugShaker.swift
//  Pods
//
//  Created by Dan Trenz on 12/10/15.
//

import UIKit
import MessageUI

@objc public protocol BugShakerDelegate {
    func shouldPresentReportPrompt() -> Bool
        @objc optional func shouldAddOtherAttachments(mailComposer: MFMailComposeViewController)
}

public class BugShaker {

    // optional delegate object that implements ShouldPresentReportPorompt and can basically disable or enable the bugshaker behavior
    static var delegate: BugShakerDelegate?

        struct Config {
            static var toRecipients: [String]?
                static var subject: String?
                static var body: String?
        }

    // MARK: - Configuration

    /**
      Set bug report email recipient(s), custom subject line and body.

      - parameter toRecipients: List of email addresses to which the report will be sent.
      - parameter subject:      Custom subject line to use for the report email.
      - parameter body:         Custom email body (plain text).
     */
    public class func configure(to toRecipients: [String]!, subject: String?, body: String?, delegate: BugShakerDelegate? = nil) {
        Config.toRecipients = toRecipients
            Config.subject = subject
            Config.body = body
            BugShaker.delegate = delegate
    }

}

extension UIViewController: MFMailComposeViewControllerDelegate {

    // MARK: - UIResponder

    open override var canBecomeFirstResponder: Bool { return true}
    
    override open func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if let delegate = BugShaker.delegate {
                if !delegate.shouldPresentReportPrompt() {
                    return
                }
            }

            let cachedScreenshot = captureScreenshot()

                presentReportPrompt(reportActionHandler: { (action) -> Void in
                        self.presentReportComposeView(screenshot: cachedScreenshot)
                        })
        }
    }

    // MARK: - Alert

    func presentReportPrompt(reportActionHandler: @escaping (UIAlertAction) -> Void) {

        let reportAction = UIAlertAction(title: "Report A Bug", style: .default, handler: reportActionHandler)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }

        if UIDevice.current.userInterfaceIdiom == .phone {
            let actionSheet = UIAlertController(
                    title: "Shake detected!",
                    message: "Would you like to report a bug?",
                    preferredStyle: .actionSheet
                    )
                actionSheet.addAction(reportAction)
                actionSheet.addAction(cancelAction)
                self.present(actionSheet, animated: true, completion: nil)
        }
        else {
            let actionSheet = UIAlertController(
                    title: "Shake detected!",
                    message: "Would you like to report a bug?",
                    preferredStyle: .alert
                    )
                actionSheet.addAction(reportAction)
                actionSheet.addAction(cancelAction)
                self.present(actionSheet, animated: true, completion: nil)
        }
    }

    // MARK: - Report methods

    /**
      Take a screenshot for the current screen state.

      - returns: Screenshot image.
     */
    func captureScreenshot() -> UIImage? {
        var screenshot: UIImage? = nil

            if let layer = UIApplication.shared.keyWindow?.layer {
                let scale = UIScreen.main.scale

                    UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);

                if let context = UIGraphicsGetCurrentContext() {
                    layer.render(in: context)
                }

                screenshot = UIGraphicsGetImageFromCurrentImageContext()

                    UIGraphicsEndImageContext()
            }

        return screenshot;
    }

    /**
      Present the user with a mail compose view with the recipient(s), subject line and body
      pre-populated, and the screenshot attached.

      - parameter screenshot: The screenshot to attach to the report.
     */
    func presentReportComposeView(screenshot: UIImage?) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()

                guard let toRecipients = BugShaker.Config.toRecipients else {
                    print("BugShaker – Error: No recipients provided. Make sure that BugShaker.configure() is called.")
                        return
                }

            mailComposer.setToRecipients(toRecipients)
                mailComposer.setSubject(BugShaker.Config.subject ?? "Bug Report")
                mailComposer.setMessageBody(BugShaker.Config.body ?? "", isHTML: false)
                mailComposer.mailComposeDelegate = self

                if let screenshot = screenshot, let screenshotJPEG = UIImageJPEGRepresentation(screenshot, CGFloat(1.0)) {
                    mailComposer.addAttachmentData(screenshotJPEG, mimeType: "image/jpeg", fileName: "screenshot.jpeg")
                }

            if let delegate = BugShaker.delegate,
                let shouldAddOtherAttachments = delegate.shouldAddOtherAttachments
                {
                    shouldAddOtherAttachments(mailComposer)
                }



            present(mailComposer, animated: true, completion: nil)
        }
    }

    // MARK: - MFMailComposeViewControllerDelegate

    public func mailComposeController(controller: MFMailComposeViewController,
            didFinishWithResult result: MFMailComposeResult,
            error: NSError?) {
        if let error = error {
            print("BugShaker – Error: \(error)")
        }

        switch result {
            case .failed:
                print("BugShaker – Bug report send failed.")
                    break;

            case .sent:
                print("BugShaker – Bug report sent!")
                    break;

            default:
                // noop
                break;
        }

        dismiss(animated: true, completion: nil)
    }

}
