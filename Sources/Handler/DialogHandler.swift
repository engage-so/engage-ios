//
//  ViewHandler.swift
//
//
//  Created by Ifeanyi Onuoha on 10/11/2024.
//

import SwiftUI

final class DialogHandler: DialogHandlerProtocol {
    static let shared = DialogHandler()
    
    func showDialog(isCarousel: Bool) {
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        if let data = (isCarousel ? carouselMap : dialogMap).data(using: .utf8) {
            do {
                let inAppPayload: InAppPayload = try JSONMapper.decode(data)
                
                if isCarousel {
                    let hostingController = UIHostingController(rootView: CarouselDialogView(
                        inAppPayload: inAppPayload,
                        onDismissRequest: {
                            print("Carousel dismiss called")
                            keyWindow.rootViewController?.dismiss(animated: true)
                        }
                    ))
                    hostingController.modalPresentationStyle = .popover
                    
                    keyWindow.rootViewController?.present(hostingController, animated: true, completion: nil)
                } else {
                    let hostingController = UIHostingController(rootView: SimpleDialogView(
                        inAppPayload: inAppPayload,
                        onDismissRequest: {
                            print("Dialog dismiss called")
                            keyWindow.rootViewController?.dismiss(animated: true)
                        }
                    ))
                    hostingController.modalPresentationStyle = .overCurrentContext
                    hostingController.modalTransitionStyle = .crossDissolve
                    hostingController.view.backgroundColor = UIColor.systemFill.withAlphaComponent(0.3)
                    
                    keyWindow.rootViewController?.present(hostingController, animated: true, completion: nil)
                }
            } catch {
                print("Error converting data to model class.\n\(error.localizedDescription)\n\(error)")
            }
        } else {
            print("Failed to convert JSON string to Data")
        }
    }
}

let dialogMap = """
        {
            "position": "center",
            "background": "#FFFFFF",
            "closeBtn": false,
            "txtColor": "#000000",
            "btnColor": "#007BFF",
            "btnTxtColor": "#FFFFFF",
            "borderRadius": 12,
            "contents": [
                [
                    {
                        "type": "text",
                        "content": "Dialog Title"
                    },
                    {
                        "type": "image",
                        "url": "https://img.freepik.com/premium-photo/woman-holding-camera-with-hat-her-head-scarf-around-her-neck_1313501-26402.jpg",
                        "width": 100
                    },
                    {
                        "type": "text",
                        "content": "This is the dialog description. It provides more details to the user."
                    },
                    {
                        "type": "button",
                        "content": "Continue",
                        "borderRadius": 8,
                        "buttonWidth": "50",
                        "action": "dismiss"
                    }
                ]
            ]
        }
"""

let carouselMap = """
        {
            "position": "carousel",
            "background": "#FFFFFF",
            "closeBtn": false,
            "txtColor": "#000000",
            "btnColor": "#007BFF",
            "btnTxtColor": "#FFFFFF",
            "borderRadius": 12,
            "contents": [
                [
                    {
                        "type": "text",
                        "content": "Dialog One"
                    },
                    {
                        "type": "image",
                        "url": "https://img.freepik.com/premium-photo/woman-holding-camera-with-hat-her-head-scarf-around-her-neck_1313501-26402.jpg",
                        "width": 100
                    },
                    {
                        "type": "text",
                        "content": "This is the dialog description. It provides more details to the user."
                    },
                    {
                        "type": "button",
                        "content": "Continue",
                        "borderRadius": 8,
                        "buttonWidth": "100",
                        "action": "dismiss"
                    }
                ],
                [
                    {
                        "type": "text",
                        "content": "Dialog Two"
                    },
                    {
                        "type": "image",
                        "url": "https://img.freepik.com/premium-photo/woman-holding-camera-with-hat-her-head-scarf-around-her-neck_1313501-26402.jpg",
                        "width": 100
                    },
                    {
                        "type": "text",
                        "content": "This is the dialog description. It provides more details to the user."
                    },
                    {
                        "type": "button",
                        "content": "Continue",
                        "borderRadius": 4,
                        "buttonWidth": "60",
                        "action": "dismiss"
                    }
                ],
                [
                    {
                        "type": "text",
                        "content": "Dialog Three"
                    },
                    {
                        "type": "image",
                        "url": "https://img.freepik.com/premium-photo/woman-holding-camera-with-hat-her-head-scarf-around-her-neck_1313501-26402.jpg",
                        "width": 100
                    },
                    {
                        "type": "text",
                        "content": "This is the dialog description. It provides more details to the user."
                    },
                    {
                        "type": "button",
                        "content": "Done",
                        "borderRadius": 16,
                        "buttonWidth": "100",
                        "action": "dismiss"
                    }
                ]
            ]
        }
"""
