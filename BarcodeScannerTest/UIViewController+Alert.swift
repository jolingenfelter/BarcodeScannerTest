//
//  UIViewController+Alert.swift

import UIKit

typealias AlertActionHandler = ((UIAlertAction) -> ())

extension UIViewController {
    func display(alert error: Error?) {
        if let error = error {
            display(alert: "Error", message: error.localizedDescription)
        }
    }
    
    func display(alert title: String, message: String, okHandler: AlertActionHandler? = nil, okIsDestructive: Bool = false, canCancel: Bool = false, cancelHandler: AlertActionHandler? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "ok", style: okIsDestructive ? .destructive : .cancel, handler: okHandler))
        
        if canCancel {
            alertController.addAction(UIAlertAction(title: "cancel", style: .default, handler: cancelHandler))
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
