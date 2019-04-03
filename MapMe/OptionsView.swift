//
//  OptionsView.swift
//  MapMe
//
//  Created by Fred Song on 3/4/19.
//  Copyright © 2019 TomTom. All rights reserved.
//

import UIKit

protocol OptionsViewDelegate: class {
    func displayMap(ID: Int, on: Bool)
}

class OptionButton: UIButton {
    
    override open var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? TTColor.GreenDark() : TTColor.GreenLight()
        }
    }
}

public class OptionsView: UIStackView {
    
    weak var delegate: OptionsViewDelegate?
    
    init(labels: [String], selectedID: Int) {
        super.init(frame: CGRect.zero)
        setup(labels: labels, selectedID: selectedID)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup(labels: ["default"], selectedID: -1)
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        setup(labels: ["default"], selectedID: -1)
    }
    
    private func setup(labels: [String], selectedID: Int) {
        distribution = .fillEqually
        spacing = 10
        for i in 0..<labels.count {
            let label = labels[i]
            addButton(ID: i, title: label, isSelected: i == selectedID)
        }
    }
    
    private func addButton(ID: Int, title: String, isSelected: Bool) {
        let button = OptionButton()
        button.layer.cornerRadius = 20
        button.setTitleColor(TTColor.Black(), for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.withSize(13)
        addArrangedSubview(button)
        button.isSelected = isSelected
        button.tag = ID
        button.addTarget(self, action: #selector(buttonTouchUpInside(button:)), for: .touchUpInside)
    }
    
    public func deselectAll() {
        for button in buttons {
            button.isSelected = false
        }
    }
    
    var buttons: [OptionButton] {
        get {
            var buttons: [OptionButton] = []
            for view in subviews {
                if let button = view as? OptionButton {
                    buttons.append(button)
                }
            }
            return buttons
        }
    }
    
    func selectAndTriggerDelegateFor(_ button: UIButton, selected: Bool) {
        button.isSelected = selected
        if let delegate = self.delegate {
            delegate.displayMap(ID: button.tag, on: selected)
        }
    }
    
    @objc public func buttonTouchUpInside(button: UIButton) {
        deselectAll()
        selectAndTriggerDelegateFor(button, selected: true)
    }
    
}
