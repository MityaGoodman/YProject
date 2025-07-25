//
//  PieChartView.swift
//  YProject
//
//  Created by Митя on 23.07.2025.
//

import UIKit

private class WeakTarget {
    weak var target: PieChartView?
    init(_ target: PieChartView) { self.target = target }
    @objc func handleAnimationFrameSafe() {
        if let target = target {
            DispatchQueue.main.async {
                target.handleAnimationFrameSafe()
            }
        }
    }
}

public class PieChartView: UIView {
    // Цвета для 6 сегментов (можно заменить на любые другие)
    private let segmentColors: [UIColor] = [
        UIColor.systemBlue,
        UIColor.systemGreen,
        UIColor.systemOrange,
        UIColor.systemRed,
        UIColor.systemPurple,
        UIColor.systemGray
    ]
    
    public var entities: [Entity] = [] {
        didSet {
            animationPhase = 1.0
            isAnimating = false
            setNeedsDisplay()
        }
    }
    
    // Агрегированные данные для отображения (максимум 6 сегментов)
    private var processedEntities: [Entity] {
        if entities.count <= 5 {
            return entities
        } else {
            let top5 = Array(entities.prefix(5))
            let othersValue = entities.dropFirst(5).reduce(Decimal(0)) { $0 + $1.value }
            let others = Entity(value: othersValue, label: "Остальные")
            return top5 + [others]
        }
    }
    
    // Анимация
    private var animationPhase: CGFloat = 1.0 // 0...1
    private var isAnimating = false
    private var oldEntities: [Entity] = []
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private let animationDuration: CFTimeInterval = 1.0
    private var newEntities: [Entity] = []
    private var displayLinkProxy: WeakTarget?
    
    private var processedOldEntities: [Entity] {
        if oldEntities.count <= 5 {
            return oldEntities
        } else {
            let top5 = Array(oldEntities.prefix(5))
            let othersValue = oldEntities.dropFirst(5).reduce(Decimal(0)) { $0 + $1.value }
            let others = Entity(value: othersValue, label: "Остальные")
            return top5 + [others]
        }
    }
    
    private func startTransitionAnimation(from old: [Entity], to new: [Entity]) {
        guard !old.isEmpty, old != new else {
            animationPhase = 1.0
            isAnimating = false
            setNeedsDisplay()
            return
        }
        oldEntities = old
        newEntities = new
        animationPhase = 0.0
        isAnimating = true
        animationStartTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLinkProxy = WeakTarget(self)
        displayLink = CADisplayLink(target: displayLinkProxy!, selector: #selector(WeakTarget.handleAnimationFrameSafe))
        objc_setAssociatedObject(displayLink!, "proxy", displayLinkProxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @MainActor
    @objc func handleAnimationFrameSafe() {
        guard self.window != nil else {
            displayLink?.invalidate()
            displayLink = nil
            displayLinkProxy = nil
            return
        }
        handleAnimationFrame()
    }
    
    public override func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
        super.removeFromSuperview()
    }
    
    @objc private func handleAnimationFrame() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let progress = min(CGFloat(elapsed / animationDuration), 1.0)
        animationPhase = progress
        setNeedsDisplay()
        if progress >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
            isAnimating = false
            oldEntities = []
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    public override func draw(_ rect: CGRect) {
        guard !processedEntities.isEmpty else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.39
        let ringWidth: CGFloat = 26
        
        if isAnimating {
            // Анимация: две фазы
            // 0...0.5 — старый график fade out + rotate 0...180
            // 0.5...1 — новый fade in + rotate 180...360
            let angle: CGFloat
            let oldAlpha: CGFloat
            let newAlpha: CGFloat
            if animationPhase < 0.5 {
                angle = .pi * animationPhase * 2 // 0...π
                oldAlpha = 1 - animationPhase * 2 // 1...0
                newAlpha = 0
            } else {
                angle = .pi + .pi * (animationPhase - 0.5) * 2 // π...2π
                oldAlpha = 0
                newAlpha = (animationPhase - 0.5) * 2 // 0...1
            }
            // Старый график
            if oldAlpha > 0 {
                ctx.saveGState()
                ctx.translateBy(x: center.x, y: center.y)
                ctx.rotate(by: angle)
                ctx.translateBy(x: -center.x, y: -center.y)
                drawDonut(ctx: ctx, center: center, radius: radius, ringWidth: ringWidth, entities: processedOldEntities, alpha: oldAlpha)
                drawLegend(ctx: ctx, center: center, radius: radius, entities: processedOldEntities, alpha: oldAlpha)
                ctx.restoreGState()
            }
            // Новый график
            if newAlpha > 0 {
                ctx.saveGState()
                ctx.translateBy(x: center.x, y: center.y)
                ctx.rotate(by: angle)
                ctx.translateBy(x: -center.x, y: -center.y)
                drawDonut(ctx: ctx, center: center, radius: radius, ringWidth: ringWidth, entities: processedEntities, alpha: newAlpha)
                drawLegend(ctx: ctx, center: center, radius: radius, entities: processedEntities, alpha: newAlpha)
                ctx.restoreGState()
            }
        } else {
            drawDonut(ctx: ctx, center: center, radius: radius, ringWidth: ringWidth, entities: processedEntities, alpha: 1.0)
            drawLegend(ctx: ctx, center: center, radius: radius, entities: processedEntities, alpha: 1.0)
        }
    }
    
    private func drawDonut(ctx: CGContext, center: CGPoint, radius: CGFloat, ringWidth: CGFloat, entities: [Entity], alpha: CGFloat) {
        let total = entities.reduce(Decimal(0)) { $0 + $1.value }
        guard total > 0 else { return }
        var startAngle = -CGFloat.pi / 2
        for (i, entity) in entities.enumerated() {
            let value = CGFloat((entity.value as NSDecimalNumber).doubleValue)
            let angle = CGFloat(value / CGFloat((total as NSDecimalNumber).doubleValue)) * 2 * .pi
            let endAngle = startAngle + angle
            ctx.setStrokeColor(segmentColors[i % segmentColors.count].withAlphaComponent(alpha).cgColor)
            ctx.setLineWidth(ringWidth)
            ctx.setLineCap(.butt)
            ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            ctx.strokePath()
            startAngle = endAngle
        }
    }
    
    private func drawLegend(ctx: CGContext, center: CGPoint, radius: CGFloat, entities: [Entity], alpha: CGFloat) {
        let total = entities.reduce(Decimal(0)) { $0 + $1.value }
        guard total > 0 else { return }
        let legendFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let legendLines: [(String, UIColor)] = entities.enumerated().map { (i, entity) in
            let percent = total == 0 ? 0 : Int(round((entity.value as NSDecimalNumber).doubleValue / (total as NSDecimalNumber).doubleValue * 100))
            let text = "\(percent)%: \(entity.label)"
            let color = segmentColors[i % segmentColors.count].withAlphaComponent(alpha)
            return (text, color)
        }
        let lineHeight: CGFloat = 16
        let totalLegendHeight = CGFloat(legendLines.count) * lineHeight
        let legendStartY = center.y - totalLegendHeight / 2
        for (i, (text, color)) in legendLines.enumerated() {
            let y = legendStartY + CGFloat(i) * lineHeight
            // Цветная точка
            let dotRect = CGRect(x: center.x - 60, y: y + 4, width: 10, height: 10)
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: dotRect)
            // Текст
            let attr: [NSAttributedString.Key: Any] = [
                .font: legendFont,
                .foregroundColor: UIColor.black.withAlphaComponent(alpha)
            ]
            let attributed = NSAttributedString(string: text, attributes: attr)
            attributed.draw(at: CGPoint(x: center.x - 45, y: y))
        }
    }
    
    public func setEntitiesAnimated(_ newEntities: [Entity]) {
        // Первая фаза: быстрое исчезновение с полным оборотом и сильным уменьшением
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
            self.transform = CGAffineTransform(rotationAngle: .pi * 2).scaledBy(x: 0.4, y: 0.4)
            self.alpha = 0
        }, completion: { _ in
            // Обновляем данные
            self.entities = newEntities
            self.setNeedsDisplay()
            self.transform = CGAffineTransform(rotationAngle: .pi * 2).scaledBy(x: 0.4, y: 0.4)
            // Вторая фаза: эффектное появление с пружинкой
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: [.curveEaseOut],
                           animations: {
                self.transform = .identity
                self.alpha = 1
            })
        })
    }
}

