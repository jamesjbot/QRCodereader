//
//  DrawingUtility.swift
//  QRCodereader
//
//  Created by James Jongsurasithiwat on 4/30/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import UIKit

protocol DrawingUtilityProtocol {
    // Utilities for adding shaped views to the view hierarchy.

    func addRectangle(rect: CGRect, toView view: UIView,
                      withColor color: UIColor)

    func addShape(points: [CGPoint], toView view: UIView,
                  withColor color: UIColor)
}

class DrawingUtility: DrawingUtilityProtocol {
    func addRectangle(rect: CGRect,
                      toView view: UIView,
                      withColor color: UIColor) {
        let newView = UIView(frame: rect)
        newView.layer.cornerRadius = 10
        newView.alpha = 0.3
        newView.backgroundColor = color
        view.addSubview(newView)
    }

    func addShape(points: [CGPoint], toView view: UIView, withColor color: UIColor) {
        let path = UIBezierPath()
        for (i,point) in points.enumerated() {
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            if (i == points.count - 1) {
                path.close()
            }

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = color.cgColor
            let rect = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            let newView = UIView(frame: rect)
            newView.alpha = 0.3
            newView.layer.addSublayer(shapeLayer)
            newView.backgroundColor = UIColor.clear
            view.addSubview(newView)
        }
    }
    /*
     + (void)addRectangle:(CGRect)rect
     toView:(UIView *)view
     withColor:(UIColor *)color {
     UIView *newView = [[UIView alloc] initWithFrame:rect];
     newView.layer.cornerRadius = 10;
     newView.alpha = 0.3;
     newView.backgroundColor = color;
     [view addSubview:newView];
     }

     + (void)addShape:(NSArray *)points
     toView:(UIView *)view
     withColor:(UIColor *)color {
     UIBezierPath *path = [[UIBezierPath alloc] init];
     for (int i = 0; i < points.count; i++) {
     CGPoint point = [points[i] CGPointValue];

     if (i == 0) {
     [path moveToPoint:point];
     } else {
     [path addLineToPoint:point];
     }

     if (i == [points count] - 1)  {
     [path closePath];
     }
     }

     CAShapeLayer *shapeLayer = [CAShapeLayer layer];
     shapeLayer.path = path.CGPath;
     shapeLayer.fillColor = color.CGColor;

     CGRect rect = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
     UIView *newView = [[UIView alloc] initWithFrame:rect];
     newView.alpha = 0.3;
     [newView.layer addSublayer:shapeLayer];
     newView.backgroundColor = [UIColor clearColor];
     [view addSubview:newView];
     }
     
     */
}
