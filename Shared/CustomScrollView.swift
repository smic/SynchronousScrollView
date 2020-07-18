//
//  CustomScrollView.swift
//  SynchronousScrollView
//
//  Created by Stephan Michels on 18.07.20.
//

import SwiftUI

#if os(macOS)

public struct CustomScrollView<Content: View>: NSViewRepresentable  {
    private let axes: Axis.Set
    private let showsIndicators: Bool
    @Binding private var scrollPosition: CGPoint
    private let content: Content
    
    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, scrollPosition: Binding<CGPoint>, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self._scrollPosition = scrollPosition
        self.content = content()
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView(frame: .zero)
        scrollView.drawsBackground = false
        
        scrollView.borderType = .noBorder
        scrollView.focusRingType = .none
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.verticalScrollElasticity = .automatic
        scrollView.horizontalScrollElasticity = .automatic
        scrollView.usesPredominantAxisScrolling = false

        let hostingView = NSHostingView(rootView: self.content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = hostingView

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
        ])
        if !self.axes.contains(.horizontal) {
            let constraint = hostingView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
        if !self.axes.contains(.vertical) {
            let constraint = hostingView.heightAnchor.constraint(equalTo: scrollView.contentView.heightAnchor)
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
        
        context.coordinator.scrollView = scrollView
        context.coordinator.hostingView = hostingView
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if scrollView.hasHorizontalScroller != self.showsIndicators {
            scrollView.hasHorizontalScroller = self.showsIndicators
        }
        if scrollView.hasVerticalScroller != self.showsIndicators {
            scrollView.hasVerticalScroller = self.showsIndicators
        }
        
        guard let hostingView = context.coordinator.hostingView else {
            return
        }
        hostingView.rootView = self.content
        
        let contentView = scrollView.contentView
        if contentView.bounds.origin != self.scrollPosition {
            contentView.scroll(to: self.scrollPosition)
            scrollView.reflectScrolledClipView(contentView)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(scrollPosition: self._scrollPosition)
    }
    
    public class Coordinator: NSObject {
        @Binding private var scrollPosition: CGPoint
        
        private var observer: AnyObject?
        fileprivate var scrollView: NSScrollView? {
            didSet {
                if oldValue === self.scrollView {
                    return
                }
                if let observer = self.observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                if let contentView = self.scrollView?.contentView {
                    contentView.postsBoundsChangedNotifications = true
                    self.observer = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: contentView, queue: nil) { (notification) in
                        DispatchQueue.main.async {
                            let newScrollPosition = self.scrollView?.contentView.bounds.origin ?? .zero
                            if self.scrollPosition != newScrollPosition {
                                self.scrollPosition = newScrollPosition
                            }
                        }
                    }
                }
            }
        }
        
        fileprivate var hostingView: NSHostingView<Content>?
        
        fileprivate init(scrollPosition: Binding<CGPoint>) {
            self._scrollPosition = scrollPosition
        }
        
        deinit {
            if let observer = self.observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

#else

public struct CustomScrollView<Content: View>: UIViewRepresentable  {
    private let axes: Axis.Set
    private let showsIndicators: Bool
    @Binding private var scrollPosition: CGPoint
    private let content: Content
    
    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, scrollPosition: Binding<CGPoint>, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self._scrollPosition = scrollPosition
        self.content = content()
    }
    
    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView(frame: .zero)

        let hostingController = UIHostingController(rootView: self.content)
        let hostingView = hostingController.view!
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        ])
        if !self.axes.contains(.horizontal) {
            let constraint = hostingView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
        if !self.axes.contains(.vertical) {
            let constraint = hostingView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
        
        context.coordinator.scrollView = scrollView
        context.coordinator.hostingController = hostingController
        
        scrollView.delegate = context.coordinator
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if scrollView.showsHorizontalScrollIndicator != self.showsIndicators {
            scrollView.showsHorizontalScrollIndicator = self.showsIndicators
        }
        if scrollView.showsVerticalScrollIndicator != self.showsIndicators {
            scrollView.showsVerticalScrollIndicator = self.showsIndicators
        }
        
        guard let hostingController = context.coordinator.hostingController else {
            return
        }
        hostingController.rootView = self.content
        
        if scrollView.contentOffset != self.scrollPosition {
            scrollView.contentOffset = self.scrollPosition
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(scrollPosition: self._scrollPosition)
    }
    
    public class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding private var scrollPosition: CGPoint
        
        fileprivate var scrollView: UIScrollView?
        fileprivate var hostingController: UIHostingController<Content>?
        
        fileprivate init(scrollPosition: Binding<CGPoint>) {
            self._scrollPosition = scrollPosition
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                let newScrollPosition = scrollView.contentOffset
                if self.scrollPosition != newScrollPosition {
                    self.scrollPosition = newScrollPosition
                }
            }
        }
    }
}

#endif
