//
//  SwipeGesture.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-17.
//

import SwiftUI

struct PageGesture: UIViewRepresentable {

    var selectPressed: (()->Void)? = nil
    var leftPressed: (()->Void)? = nil
    var rightPressed: (()->Void)? = nil
    var upPressed: (()->Void)? = nil
    var downPressed: (()->Void)? = nil

    func makeCoordinator() -> PageGesture.Coordinator {
        return PageGesture.Coordinator(parent1: self)
    }

    func makeUIView(context: UIViewRepresentableContext<PageGesture>) -> UIView {
        let view = ClickableView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        let select = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.select))
        select.delegate = context.coordinator
        select.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)];

        let left = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.left))
        left.delegate = context.coordinator
        left.allowedPressTypes = [NSNumber(value: UIPress.PressType.leftArrow.rawValue)];

        let right = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.right))
        right.allowedPressTypes = [NSNumber(value: UIPress.PressType.rightArrow.rawValue)];
        right.delegate = context.coordinator
        
        let up = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.up))
        up.allowedPressTypes = [NSNumber(value: UIPress.PressType.upArrow.rawValue)];
        up.delegate = context.coordinator
        
        let down = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.down))
        down.allowedPressTypes = [NSNumber(value: UIPress.PressType.downArrow.rawValue)];
        down.delegate = context.coordinator
        
        view.addGestureRecognizer(left)
        view.addGestureRecognizer(right)
        view.addGestureRecognizer(up)
        view.addGestureRecognizer(down)
        view.addGestureRecognizer(select)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PageGesture>) {
        uiView.backgroundColor = .clear
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var parent : PageGesture

        init(parent1 : PageGesture){
            parent = parent1
        }

        @objc func left(gesture: UITapGestureRecognizer){
            print("left arrow")
            //parent.page = parent.page - 2
            if let callback = parent.leftPressed {
                callback()
            }
        }

        @objc func right(gesture: UITapGestureRecognizer){
            print("right arrow")
            //parent.page = parent.page + 2
            if let callback = parent.rightPressed {
                callback()
            }
        }
        
        @objc func up(gesture: UITapGestureRecognizer){
            print("up arrow")
            //parent.page = parent.page + 2
            if let callback = parent.upPressed {
                callback()
            }
        }
        
        @objc func down(gesture: UITapGestureRecognizer){
            print("down arrow")
            //parent.page = parent.page + 2
            if let callback = parent.downPressed {
                callback()
            }
        }
        
        @objc func select(gesture: UITapGestureRecognizer){
            print("select")
            //parent.page = parent.page + 2
            if let callback = parent.selectPressed {
                callback()
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

class ClickableView: UIProgressView {
    //weak var delegate: ClickableHackDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses {
            if item.type == .select {
                debugPrint("UI Select")
            }
            if item.type == .leftArrow {
                debugPrint("UI Left")
            }
            if item.type == .rightArrow {
                debugPrint("UI Right")
            }
            if item.type == .upArrow {
                debugPrint("UI Up")
            }
            if item.type == .downArrow {
                debugPrint("UI Down")
            }
        }
        
    }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        //delegate?.focus(focused: isFocused)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //This is probably what's needed for the TapGestureRecognizer to work on tvos for some reason
    override var canBecomeFocused: Bool {
        return true
    }
}
