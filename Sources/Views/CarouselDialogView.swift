//
//  SwiftUIView.swift
//
//
//  Created by Ifeanyi Onuoha on 10/11/2024.
//

import SwiftUI

struct CarouselDialogView: View {
    var inAppPayload: InAppPayload
    var onDismissRequest: () -> Void
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            PageViewController(
                currentPage: $currentPage,
                pages: inAppPayload.contents.map({ contents in
                    ScrollView {
                        ForEach(contents, id: \.self) { content in
                            switch content.type {
                            case .row:
                                Text("Row")
                            case .image:
                                GeometryReader { geometry in
                                    NetworkImageView(
                                        imageUrl: content.url ?? "",
                                        radius: inAppPayload.radius
                                    )
                                    .frame(width: geometry.size.width * content.imageMaxWidth)
                                }
                                .aspectRatio(16/9, contentMode: .fit)
                            case .text:
                                Text(content.content ?? "")
                                    .multilineTextAlignment(.center)
                            default:
                                EmptyView()
                            }
                        }
                    }
                    .padding()
                })
            )
            
            Spacer(minLength: 20)
            
            HStack {
                ForEach(0...inAppPayload.contents.count - 1, id: \.self) { i in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(i == currentPage ? inAppPayload.buttonColor : Color.gray)
                    
                }
            }
            
            Spacer(minLength: 20)
            
            ForEach(inAppPayload.contents[currentPage], id: \.self) { content in
                switch content.type {
                case .button:
                    GeometryReader { geometry in
                        Button(content.content ?? "") {
                            if currentPage < inAppPayload.contents.count - 1 {
                                currentPage += 1
                            } else {
                                onDismissRequest()
                            }
                        }
                        .padding()
                        .if(content.buttonFillWidth) { view in
                            view.frame(width: geometry.size.width * content.buttonMaxWidth)
                        }
                        .background(inAppPayload.buttonColor)
                        .foregroundColor(inAppPayload.buttonTextColor)
                        .cornerRadius(content.butonRadius)
                        .frame(width: geometry.size.width, alignment: .center)
                        
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                    
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    if let data = carouselMap.data(using: .utf8) {
        do {
            let inAppPayload: InAppPayload = try JSONMapper.decode(data)
            
            return CarouselDialogView(
                inAppPayload: inAppPayload,
                onDismissRequest: {
                    print("Carousel dismiss called")
                }
            )
        } catch {
            print("Error converting data to model class.\n\(error.localizedDescription)\n\(error)")
            return Rectangle()
        }
    } else {
        print("Failed to convert JSON string to Data")
        return Rectangle()
    }
}

struct PageViewController<Page: View>: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    var pages: [Page]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: .forward,
            animated: true
        )
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var controllers: [UIViewController]
        
        init(_ pageViewController: PageViewController) {
            parent = pageViewController
            controllers = parent.pages.map { UIHostingController(rootView: $0) }
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            return index == 0 ? nil : controllers[index - 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            return index + 1 == controllers.count ? nil : controllers[index + 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
            }
        }
    }
}
