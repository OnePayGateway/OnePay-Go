//
//  DateTimeSelectionView.swift
//  CERTIFY Vendor
//
//  Created by Palani Krishnan on 2/8/22.
//

import Foundation
import UIKit

class DateTimeSelectionView: UIView {
    
    @IBOutlet weak var calenderContainer: UIView!
    
    var datePicker : UIDatePicker!
    var calenderView: CalendarView!
    
    var apptDate:Date?
    
    
    func loadUI() {
        calenderView = CalendarView()
        calenderView.didSelectDate = { [weak self] selectedDate in
            guard let self = self else { return }
            self.apptDate = selectedDate?.date
            print(selectedDate?.date.shortDateFormat as Any)
        }
        setupConstraints()
        addShaddow(view: calenderContainer)
    }
    
    func addShaddow(view: UIView) {
        view.layer.cornerRadius = 10
        view.clipsToBounds = false
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = 5.0
        view.layer.shadowOpacity = 0.5
    }
    
    private func setupConstraints() {
        let mainStack = UIStackView(arrangedSubviews: [calenderView])
        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.spacing = 16
       
       // mainStack.setCustomSpacing(8, after: selectedDateLabel)
        calenderContainer.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: calenderContainer.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: calenderContainer.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: calenderContainer.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: calenderContainer.bottomAnchor),
        ])
    }
    
}
