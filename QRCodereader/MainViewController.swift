//
//  ViewController.swift
//  QRCodereader
//
//  Created by James Jongsurasithiwat on 4/27/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import UIKit
import GoogleMobileVision
import AVFoundation
import AVKit

class MainViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBAction func takePicture(_ sender: Any) {
        initialize()
    }

    private var imagePickerController: UIImagePickerController?
    private var barcodeDetector: GMVDetector?

    private var defaultOrientation: UIDeviceOrientation?
    // MARK: FUNCTIONS

    // MARK: Life Cycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        //defaultOrientation = UIDeviceOrientation.unknown
    }

    private func initialize() {
        let cameraAvailable: Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        if cameraAvailable {
            imagePickerController = UIImagePickerController()
            imagePickerController?.sourceType = UIImagePickerControllerSourceType.camera
            if let imagePickerController = imagePickerController  {
                imagePickerController.delegate = self
                print("Presenting image picker controller")
                present(imagePickerController, animated: true, completion: nil)
                print(type(of:GMVDetectorBarcodeFormat.qrCode))
                print(GMVDetectorBarcodeFormat.qrCode)
                print("Presented image picker controller")
            }
        } else {
            let image: UIImage = UIImage(named: "multi_values.png")!
            initializeBarcodeDetector()
            barcodeFeatureExtraction(image: image)
        }
    }

    fileprivate func initializeBarcodeDetector() {
        let op: [AnyHashable:Any] = [GMVDetectorBarcodeFormats: GMVDetectorBarcodeFormat.qrCode]
        barcodeDetector = GMVDetector(ofType: GMVDetectorTypeBarcode, options: nil)
        assert(barcodeDetector != nil)
    }

    fileprivate func barcodeFeatureExtraction(image: UIImage ) {
        // Establish the image orientation and detect feature using GMVDetector

        let devicePosition: AVCaptureDevicePosition = AVCaptureDevicePosition.back
        let deviceOrientation = UIDevice.current.orientation
        let orientation: GMVImageOrientation = GMVUtility.imageOrientation(from: deviceOrientation, with: devicePosition, defaultDeviceOrientation: UIDeviceOrientation.unknown)
        let options: [AnyHashable:Any] = [GMVDetectorImageOrientation: orientation]
        let locationOptions = [GMVDetectorImageOrientation:GMVImageOrientation.topLeft]

        textView.text.append("Looking for orientation \(orientation.rawValue)\n")

        if let barcodes = barcodeDetector?.features(in: image, options: nil ) {
            output(barcodes: barcodes)
        } else {
            textView.text.append("Sorry Couldn't find any barcodes\n")
        }
    }

    fileprivate func output(barcodes: [GMVFeature]) {
        textView.text.append("Barcodes: \(barcodes.count)\n")
        for feature in barcodes {
            let barcodeFeature = feature as? GMVBarcodeFeature
            textView.text.append("a feature raw value: \(barcodeFeature?.rawValue)\n")
            textView.text.append("a feature display value: \(barcodeFeature?.displayValue)\n")
            textView.text.append("a feature format: \(barcodeFeature?.format)\n")
            textView.text.append("a feature value format\(barcodeFeature?.valueFormat)\n")
            textView.text.append("a feature url: \(barcodeFeature?.url)\n")
        }
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        textView.text.append("\n")
        textView.text.append("finished picking media\n")
        var imageView = UIImageView()
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        initializeBarcodeDetector()
        barcodeFeatureExtraction(image: imageView.image!)
        textView.text.append("Extraction complete")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("You cancelled the image picker controller")
        picker.dismiss(animated: true, completion: nil)
    }


}
