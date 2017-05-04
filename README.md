# QRCodereader

## Overview
QRCodereader is a test program to use Google Mobile Vision framework

## Technologies Used
UIKit, Google Mobile Vision  

## Example usage

Initially the camera will pop up, take a picture of a barcode.
It will return back to the information screen, where the information for that barcode will be listed.

## How to set up the dev environment
First have cocoapods installed, if you don't have it there are instructions at https://cocoapods.org

Go to https://github.com/jamesjbot/QRCodereader and download the zip file

After downloading, please navigate to the QRCodereader folder and type `pod install`

Then go into the folder QRCodereader, open QRCodereader.xcworkspace.

Or

From terminal (with git installed), type 
```
git clone https://github.com/jamesjbot/QRCodereader.git
cd QRCodereader
pod install
open QRCodereader.xcworkspace
```

Then build the project.

## How to ship a change
Changes are not accepted at this time

## Know bugs
Some time the detector cannot detect the barcode.    
QRCodes are very hard for the detector to read (try to scan single QRCodes in landscape mode).
 
## Change log
* 01-05-2017 Initial Commit

## License and author info
All rights reserved
Author: jongs.j@gmail.com
