#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let w = CGFloat(size)
let h = CGFloat(size)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Flip coordinate system (CG is bottom-left origin)
ctx.translateBy(x: 0, y: h)
ctx.scaleBy(x: 1, y: -1)

// MARK: - Background gradient
let bgColors: [CGFloat] = [
    0.15, 0.40, 0.85, 1.0,
    0.08, 0.20, 0.55, 1.0,
    0.05, 0.12, 0.35, 1.0
]
let bgLocations: [CGFloat] = [0.0, 0.5, 1.0]
if let gradient = CGGradient(colorSpace: colorSpace, colorComponents: bgColors, locations: bgLocations, count: 3) {
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w, y: h), options: [])
}

// MARK: - Radial glow
let glowColors: [CGFloat] = [
    1.0, 1.0, 1.0, 0.12,
    1.0, 1.0, 1.0, 0.03,
    1.0, 1.0, 1.0, 0.0
]
let glowLocations: [CGFloat] = [0.0, 0.5, 1.0]
if let glow = CGGradient(colorSpace: colorSpace, colorComponents: glowColors, locations: glowLocations, count: 3) {
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: w * 0.5, y: h * 0.48), startRadius: 0, endCenter: CGPoint(x: w * 0.5, y: h * 0.48), endRadius: w * 0.4, options: [])
}

// MARK: - Cloud-brain shape
func cloudBrainPath() -> CGMutablePath {
    let path = CGMutablePath()
    let baseY = h * 0.68
    let baseLeft = w * 0.18
    let baseRight = w * 0.82

    path.move(to: CGPoint(x: baseLeft, y: baseY))

    // Left cloud puffs
    path.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.52),
                  control1: CGPoint(x: w * 0.10, y: baseY),
                  control2: CGPoint(x: w * 0.08, y: h * 0.58))
    path.addCurve(to: CGPoint(x: w * 0.18, y: h * 0.34),
                  control1: CGPoint(x: w * 0.10, y: h * 0.44),
                  control2: CGPoint(x: w * 0.10, y: h * 0.36))
    path.addCurve(to: CGPoint(x: w * 0.32, y: h * 0.24),
                  control1: CGPoint(x: w * 0.22, y: h * 0.28),
                  control2: CGPoint(x: w * 0.26, y: h * 0.24))

    // Top transition
    path.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.22),
                  control1: CGPoint(x: w * 0.38, y: h * 0.22),
                  control2: CGPoint(x: w * 0.43, y: h * 0.20))
    // Brain fissure dip
    path.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.23),
                  control1: CGPoint(x: w * 0.50, y: h * 0.25),
                  control2: CGPoint(x: w * 0.51, y: h * 0.25))

    // Right brain lobes
    path.addCurve(to: CGPoint(x: w * 0.68, y: h * 0.24),
                  control1: CGPoint(x: w * 0.57, y: h * 0.19),
                  control2: CGPoint(x: w * 0.63, y: h * 0.20))
    path.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.32),
                  control1: CGPoint(x: w * 0.74, y: h * 0.24),
                  control2: CGPoint(x: w * 0.80, y: h * 0.26))
    path.addCurve(to: CGPoint(x: w * 0.82, y: h * 0.40),
                  control1: CGPoint(x: w * 0.83, y: h * 0.35),
                  control2: CGPoint(x: w * 0.84, y: h * 0.38))
    path.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.52),
                  control1: CGPoint(x: w * 0.86, y: h * 0.44),
                  control2: CGPoint(x: w * 0.88, y: h * 0.48))
    path.addCurve(to: CGPoint(x: baseRight, y: baseY),
                  control1: CGPoint(x: w * 0.88, y: h * 0.60),
                  control2: CGPoint(x: w * 0.88, y: baseY))

    path.addLine(to: CGPoint(x: baseLeft, y: baseY))
    path.closeSubpath()
    return path
}

let shape = cloudBrainPath()

// Shadow
ctx.saveGState()
ctx.translateBy(x: 3, y: 5)
ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.25))
ctx.addPath(shape)
ctx.fillPath()
ctx.restoreGState()

// Main fill gradient (cloud-blue to brain-pink)
ctx.saveGState()
ctx.addPath(shape)
ctx.clip()
let fillColors: [CGFloat] = [
    0.85, 0.92, 1.0, 1.0,
    0.95, 0.88, 0.95, 1.0,
    0.92, 0.82, 0.90, 1.0
]
let fillLocations: [CGFloat] = [0.0, 0.5, 1.0]
if let fillGrad = CGGradient(colorSpace: colorSpace, colorComponents: fillColors, locations: fillLocations, count: 3) {
    ctx.drawLinearGradient(fillGrad, start: CGPoint(x: w * 0.15, y: h * 0.5), end: CGPoint(x: w * 0.85, y: h * 0.5), options: [])
}
ctx.restoreGState()

// Highlight on top
ctx.saveGState()
ctx.addPath(shape)
ctx.clip()
let hlColors: [CGFloat] = [
    1.0, 1.0, 1.0, 0.5,
    1.0, 1.0, 1.0, 0.0
]
let hlLocations: [CGFloat] = [0.0, 1.0]
if let hlGrad = CGGradient(colorSpace: colorSpace, colorComponents: hlColors, locations: hlLocations, count: 2) {
    ctx.drawLinearGradient(hlGrad, start: CGPoint(x: w * 0.5, y: h * 0.2), end: CGPoint(x: w * 0.5, y: h * 0.55), options: [])
}
ctx.restoreGState()

// Outline
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.4))
ctx.setLineWidth(w * 0.004)
ctx.addPath(shape)
ctx.strokePath()

// MARK: - Brain sulci
ctx.setStrokeColor(CGColor(red: 0.7, green: 0.6, blue: 0.72, alpha: 0.5))
ctx.setLineWidth(w * 0.008)
ctx.setLineCap(.round)

// Central sulcus
let sulci = CGMutablePath()
sulci.move(to: CGPoint(x: w * 0.50, y: h * 0.25))
sulci.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.62),
               control1: CGPoint(x: w * 0.51, y: h * 0.38),
               control2: CGPoint(x: w * 0.50, y: h * 0.52))

// Upper fold
sulci.move(to: CGPoint(x: w * 0.54, y: h * 0.32))
sulci.addCurve(to: CGPoint(x: w * 0.76, y: h * 0.33),
               control1: CGPoint(x: w * 0.62, y: h * 0.28),
               control2: CGPoint(x: w * 0.70, y: h * 0.30))

// Middle fold
sulci.move(to: CGPoint(x: w * 0.53, y: h * 0.43))
sulci.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.44),
               control1: CGPoint(x: w * 0.62, y: h * 0.40),
               control2: CGPoint(x: w * 0.74, y: h * 0.40))

// Lower fold
sulci.move(to: CGPoint(x: w * 0.53, y: h * 0.54))
sulci.addCurve(to: CGPoint(x: w * 0.82, y: h * 0.55),
               control1: CGPoint(x: w * 0.63, y: h * 0.51),
               control2: CGPoint(x: w * 0.75, y: h * 0.51))

ctx.addPath(sulci)
ctx.strokePath()

// MARK: - Lightning bolt
let bolt = CGMutablePath()
bolt.move(to: CGPoint(x: w * 0.50, y: h * 0.60))
bolt.addLine(to: CGPoint(x: w * 0.46, y: h * 0.70))
bolt.addLine(to: CGPoint(x: w * 0.49, y: h * 0.70))
bolt.addLine(to: CGPoint(x: w * 0.46, y: h * 0.80))
bolt.addLine(to: CGPoint(x: w * 0.54, y: h * 0.72))
bolt.addLine(to: CGPoint(x: w * 0.51, y: h * 0.72))
bolt.addLine(to: CGPoint(x: w * 0.55, y: h * 0.60))
bolt.closeSubpath()

// Bolt fill gradient
ctx.saveGState()
ctx.addPath(bolt)
ctx.clip()
let boltColors: [CGFloat] = [
    1.0, 0.85, 0.2, 1.0,
    1.0, 0.65, 0.1, 1.0
]
let boltLocations: [CGFloat] = [0.0, 1.0]
if let boltGrad = CGGradient(colorSpace: colorSpace, colorComponents: boltColors, locations: boltLocations, count: 2) {
    ctx.drawLinearGradient(boltGrad, start: CGPoint(x: w * 0.47, y: h * 0.58), end: CGPoint(x: w * 0.53, y: h * 0.78), options: [])
}
ctx.restoreGState()

// Bolt outline
ctx.setStrokeColor(CGColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.6))
ctx.setLineWidth(w * 0.003)
ctx.addPath(bolt)
ctx.strokePath()

// MARK: - Save PNG
guard let image = ctx.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let outputPath = "WeatherWise/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let url = URL(fileURLWithPath: outputPath)

guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
if CGImageDestinationFinalize(dest) {
    print("App icon saved to \(outputPath)")
} else {
    print("Failed to write PNG")
    exit(1)
}
