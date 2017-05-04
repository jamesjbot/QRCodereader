//
//  CameraViewController.swift
//  QRCodereader
//
//  Created by James Jongsurasithiwat on 4/30/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import UIKit
import GoogleMobileVision
import AVKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var placeHolder: UIView!
    @IBOutlet weak var overLay: UIView!

    var session: AVCaptureSession?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var lastKnownDeviceOrientation: UIDeviceOrientation?

    var barcodeDetector: GMVDetector?

    // MARK: Functions
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        videoDataOutput = nil
        videoDataOutputQueue = DispatchQueue(label: "VideoDataQueue",
                                             qos: .utility,
                                             attributes: .initiallyInactive,
                                             autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                             target: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetMedium
        updateCameraSelection()

        // Set up video processing pipeline
        setUpVideoProcssing()

        // Set up camera preview
        setUpCameraPreview()

        barcodeDetector = GMVDetector(ofType: GMVDetectorTypeBarcode,
                                           options: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        session?.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        session?.stopRunning()
    }

/*
     - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
     duration:(NSTimeInterval)duration {
     // Camera rotation needs to be manually set when rotation changes.
     if (self.previewLayer) {
     if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
     self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
     } else if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
     self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
     } else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
     self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
     } else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
     self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
     }
     }
     }
*/
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        guard previewLayer != nil else {
            return
        }
        if toInterfaceOrientation == UIInterfaceOrientation.portrait {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
        } else if toInterfaceOrientation == UIInterfaceOrientation.portraitUpsideDown {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        } else if toInterfaceOrientation == UIInterfaceOrientation.landscapeLeft {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        } else if toInterfaceOrientation == UIInterfaceOrientation.landscapeRight {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }
    }

    func scaleRect(rect: CGRect,
                   xScale: CGFloat,
                   yScale: CGFloat,
                   offset: CGPoint) -> CGRect {
        var resultRect: CGRect = CGRect(x: rect.origin.x * xScale,
                                        y: rect.origin.y * yScale,
                                        width: rect.size.width * xScale,
                                        height: rect.size.height * yScale)
        resultRect = resultRect.offsetBy(dx: offset.x, dy: offset.y)
        return resultRect

    }

    /*
     #pragma mark - AVCaptureVideoPreviewLayer Helper method

     - (CGRect)scaleRect:(CGRect)rect
     xScale:(CGFloat)xscale
     yScale:(CGFloat)yscale
     offset:(CGPoint)offset {
     CGRect resultRect = CGRectMake(rect.origin.x * xscale,
     rect.origin.y * yscale,
     rect.size.width * xscale,
     rect.size.height * yscale);
     resultRect = CGRectOffset(resultRect, offset.x, offset.y);
     return resultRect;
     }

    */
    func scalePoint(point: CGPoint,
                    xScale: CGFloat,
                    yScale: CGFloat,
                    offset: CGPoint) -> CGPoint {
        let resultPoint = CGPoint(x: point.x * xScale, y: point.y * yScale)
        return resultPoint
    }
    /*
     - (CGPoint)scalePoint:(CGPoint)point
     xScale:(CGFloat)xscale
     yScale:(CGFloat)yscale
     offset:(CGPoint)offset {
     CGPoint resultPoint = CGPointMake(point.x * xscale + offset.x, point.y * yscale + offset.y);
     return resultPoint;
     }
     
     */

    func setLastKnownDeviceOrientation(orientation: UIDeviceOrientation) {
        if orientation != UIDeviceOrientation.unknown &&
            orientation != UIDeviceOrientation.faceUp &&
            orientation != UIDeviceOrientation.faceDown {
                lastKnownDeviceOrientation = orientation
        }
    }

    /*

     - (void)setLastKnownDeviceOrientation:(UIDeviceOrientation)orientation {
     if (orientation != UIDeviceOrientationUnknown &&
     orientation != UIDeviceOrientationFaceUp &&
     orientation != UIDeviceOrientationFaceDown) {
     _lastKnownDeviceOrientation = orientation;
     }
     }

     */

    func computeCameraDisplayFrameScaleProperties(sampleBuffer: CMSampleBuffer,
                                                  previewFrameSize: inout CGSize,
                                                  previewYScale: inout CGFloat,
                                                  previewXScale: inout CGFloat,
                                                  previewOffset: inout CGPoint) {
        let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        let cleanAperture: CGRect = CMVideoFormatDescriptionGetCleanAperture(formatDescription, false)
        var parentFrameSize: CGSize?
        if previewFrameSize.equalTo(CGSize.zero) {
            parentFrameSize = UIScreen.main.bounds.size
        } else {
            parentFrameSize = previewFrameSize
        }

        // Assumes AVLayerVideoGravityResizeAspect
        let cameraRatio: CGFloat = cleanAperture.size.height / cleanAperture.size.width
        let viewRatio: CGFloat = (parentFrameSize?.width)! / (parentFrameSize?.height)!
        var xScale: CGFloat = 1
        var yScale: CGFloat = 1
        var videoBox = CGRect.zero
        if viewRatio > cameraRatio {
            videoBox.size.width = (parentFrameSize?.height)! * cleanAperture.size.width / cleanAperture.size.height
            videoBox.size.height = (parentFrameSize?.height)!
            videoBox.origin.x = (videoBox.size.width - ((parentFrameSize?.width) ?? 0)) / 2
            videoBox.origin.y = ((parentFrameSize?.height)! - videoBox.size.height) / 2
            xScale = (videoBox.size.width / cleanAperture.size.height)
            yScale = (videoBox.size.height / cleanAperture.size.width)
            previewYScale = yScale
            previewXScale = xScale
            previewOffset = videoBox.origin
        }
    }

    func captureOutput(captureOutput: AVCaptureOutput,
                       sampleBuffer: CMSampleBuffer,
                       connection: AVCaptureOutput) {
        let image: UIImage = GMVUtility.sampleBufferTo32RGBA(sampleBuffer)
        let devicePosition: AVCaptureDevicePosition = AVCaptureDevicePosition.back

        // Establish the image orientation and detect feature using GMVDetector
        let deviceOrientation = UIDevice.current.orientation
        let orientation: GMVImageOrientation = GMVUtility.imageOrientation(from: deviceOrientation, with: devicePosition, defaultDeviceOrientation: lastKnownDeviceOrientation!)
        let options: [AnyHashable:Any] = [GMVDetectorImageOrientation: orientation]
        let barcodes: [GMVFeature] = (barcodeDetector?.features(in: image, options: options)) ?? []
        print(barcodes)
        var yScale: CGFloat = 1
        var xScale: CGFloat = 1
        var offset: CGPoint = CGPoint.zero
        var previewSize = previewLayer?.frame.size
        computeCameraDisplayFrameScaleProperties(sampleBuffer: sampleBuffer, previewFrameSize: &previewSize!, previewYScale: &yScale, previewXScale: &xScale, previewOffset: &offset)
        DispatchQueue.main.sync {
            for featureView in overLay.subviews {
                featureView.removeFromSuperview()
            }
        }
        // Display detected feature in overlay
        for barcode in (barcodes as! [GMVBarcodeFeature]) {
            let p0: CGPoint = scalePoint(point: barcode.cornerPoints[0].cgPointValue, xScale: xScale, yScale: yScale, offset: offset)
            let p1: CGPoint = scalePoint(point: barcode.cornerPoints[1].cgPointValue, xScale: xScale, yScale: yScale, offset: offset)
            let p2: CGPoint = scalePoint(point: barcode.cornerPoints[2].cgPointValue, xScale: xScale, yScale: yScale, offset: offset)
            let p3: CGPoint = scalePoint(point: barcode.cornerPoints[3].cgPointValue, xScale: xScale, yScale: yScale, offset: offset)
        let points: [CGPoint] = [p0, p1, p2, p3]
        // drawing utility addShape
        let drawingUtility = DrawingUtility()
        drawingUtility.addShape(points: points, toView: overLay, withColor: UIColor.purple)
        let textRect = CGRect(x: p0.x, y: p3.y, width: barcode.bounds.size.width, height: 50)
        let label: UILabel = UILabel(frame: textRect)
        label.text = barcode.rawValue
        label.adjustsFontSizeToFitWidth = true
        overLay.addSubview(label)
        }
    }

    /*


     dispatch_sync(dispatch_get_main_queue(), ^{
     // Remove previously added feature
     for (UIView *featureview in self.overlayView.subviews) {
     [featureview removeFromSuperview];
     }

     // Display detected features in overlay.

     NSArray *points = @[[NSValue valueWithCGPoint:p0], [NSValue valueWithCGPoint:p1],
     [NSValue valueWithCGPoint:p2], [NSValue valueWithCGPoint:p3]];
     [DrawingUtility addShape:points toView:self.overlayView withColor:[UIColor purpleColor]];

     CGRect textRect = CGRectMake(p0.x, p3.y, barcode.bounds.size.width, 50);
     UILabel *label = [[UILabel alloc] initWithFrame:textRect];
     label.text = barcode.rawValue;
     [self.overlayView addSubview:label];
     }
     });
     }



 */

    func setUpCameraPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.backgroundColor = UIColor.white.cgColor
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        var rootLayer = placeHolder.layer
        rootLayer.masksToBounds = true
        previewLayer?.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer!)
    }


    func setUpVideoProcssing() {
        videoDataOutput = AVCaptureVideoDataOutput()
        let rgbOutputSetting: [AnyHashable: Any]! = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:kCVPixelFormatType_32BGRA]
        videoDataOutput?.videoSettings = rgbOutputSetting
        if (session?.canAddOutput(videoDataOutput))! {
            videoDataOutput?.alwaysDiscardsLateVideoFrames = true
            videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            session?.addOutput(videoDataOutput)
        } else {
            // cleanUpVideoProcessing()
        }

    }

    func updateCameraSelection() {
        session?.beginConfiguration()

        // Remove old inputs
        guard let oldInputs: Array = (session?.inputs) else {
            return
        }
        for oldInput in oldInputs {
            session?.removeInput(oldInput as! AVCaptureInput)
        }
        let desiredPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.back
        if let input: AVCaptureDeviceInput = captureDeviceInputForPosition(desiredPosition: desiredPosition) {
            session?.addInput(input)
        } else {
            for oldInput in oldInputs {
                session?.addInput(oldInput as! AVCaptureInput)
            }
        }
        session?.commitConfiguration()
    }

    func captureDeviceInputForPosition(desiredPosition:AVCaptureDevicePosition) -> AVCaptureDeviceInput? {
        let device: AVCaptureDevice? = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            if (device?.position == desiredPosition) {
                //let error: NSError = nil
                let input = try? AVCaptureDeviceInput(device: device)
                if let input = input {
                    return input
                } else {
                    print("Error could not initialize AVMediaTypeVideo")
                }
            }
        return nil
    }
}





















