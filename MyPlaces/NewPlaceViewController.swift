//
//  NewPlaceViewController.swift
//  MyPlaces
//
//  Created by Максим Мосалёв on 23.11.2022.
//

import UIKit

class NewPlaceViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()

     
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            
        } else {
            view.endEditing(true)
        }
    }



}

// MARK: Text field delegate

extension NewPlaceViewController: UITextFieldDelegate {
    
    // Keyboard hiding after "done" button pressed
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
