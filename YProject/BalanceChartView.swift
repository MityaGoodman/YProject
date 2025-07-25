//
//  BalanceChartView.swift
//  YProject
//
//  Created by Митя on 24.07.2025.
//

import SwiftUI
import Charts

struct BalanceChartData: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Decimal
}

enum ChartMode: String, CaseIterable, Identifiable {
    case days = "Дни"
    case months = "Месяцы"
    var id: String { rawValue }
}

// Возвращает первый день месяца для заданной даты
private func firstDayOfMonth(for date: Date) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components) ?? date
}

// Добавляю модификатор для условного применения chartXScale
struct MonthlyXScaleModifier: ViewModifier {
    let isMonthly: Bool
    let xDomain: [Date]
    func body(content: Content) -> some View {
        if isMonthly && xDomain.count >= 2 && Set(xDomain).count >= 2 {
            content.chartXScale(domain: xDomain)
        } else {
            content
        }
    }
}

struct BalanceChartView: View {
    let data: [BalanceChartData]
    let monthlyData: [BalanceChartData]?
    
    @State private var chartMode: ChartMode = .days
    @State private var selectedIndex: Int? = nil
    @State private var dragLocation: CGPoint = .zero
    
    var body: some View {
        let chartData = chartMode == .days ? data : (monthlyData ?? data)
        let isMonthly = chartMode == .months
        // Безопасные данные для графика
        var safeChartData: [BalanceChartData]
        var xDomain: [Date] = []
        if isMonthly {
            if chartData.isEmpty {
                let now = firstDayOfMonth(for: Date())
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: now) {
                    safeChartData = [
                        BalanceChartData(date: prev, balance: 0),
                        BalanceChartData(date: now, balance: 0)
                    ]
                    xDomain = [prev, now]
                } else {
                    safeChartData = [BalanceChartData(date: now, balance: 0)]
                    xDomain = [now]
                }
            } else if chartData.count == 1 {
                let only = firstDayOfMonth(for: chartData[0].date)
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: only) {
                    safeChartData = [
                        BalanceChartData(date: prev, balance: 0),
                        BalanceChartData(date: only, balance: chartData[0].balance)
                    ]
                    xDomain = [prev, only]
                } else {
                    safeChartData = [BalanceChartData(date: only, balance: chartData[0].balance)]
                    xDomain = [only]
                }
            } else {
                safeChartData = chartData
                xDomain = chartData.map { firstDayOfMonth(for: $0.date) }
            }
        } else {
            if chartData.isEmpty {
                let now = Date()
                safeChartData = [BalanceChartData(date: now, balance: 0)]
            } else {
                safeChartData = chartData
            }
            xDomain = safeChartData.map { $0.date }
        }
        let minBalance = safeChartData.map { NSDecimalNumber(decimal: $0.balance).doubleValue }.min() ?? 0
        let maxBalance = safeChartData.map { NSDecimalNumber(decimal: $0.balance).doubleValue }.max() ?? 0
        let yMin = minBalance == maxBalance ? minBalance - 100 : minBalance - 100
        let yMax = minBalance == maxBalance ? maxBalance + 100 : maxBalance + 100

        return VStack {
            Picker("Режим", selection: $chartMode) {
                ForEach(ChartMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            ZStack {
                Chart(safeChartData) { item in
                    BarMark(
                        x: .value("Дата", chartMode == .days ? item.date : firstDayOfMonth(for: item.date)),
                        y: .value("Баланс", NSDecimalNumber(decimal: item.balance).doubleValue)
                    )
                    .foregroundStyle((item.balance >= 0) ? .green : .red)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    if chartMode == .days {
                        AxisMarks(values: .automatic(desiredCount: 6)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    } else {
                        AxisMarks(values: xDomain) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).year())
                        }
                    }
                }
                .chartXAxisLabel("Месяц")
                .chartYScale(domain: yMin...yMax)
                .frame(height: 200)
                .frame(minWidth: 220)
                .padding(.bottom, 24)
                .padding(.leading, 12)
                .modifier(MonthlyXScaleModifier(isMonthly: isMonthly, xDomain: xDomain))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.spring(), value: chartMode)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    dragLocation = value.location
                                    if let index = findNearestBar(location: value.location, proxy: proxy, data: safeChartData, geo: geo) {
                                        selectedIndex = index
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        selectedIndex = nil
                                    }
                                }
                            )
                    }
                }
                if let selectedIndex = selectedIndex, safeChartData.indices.contains(selectedIndex) {
                    let item = safeChartData[selectedIndex]
                    ChartPopupView(item: item, mode: chartMode)
                        .position(x: dragLocation.x, y: 40)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
    
    private func findNearestBar(location: CGPoint, proxy: ChartProxy, data: [BalanceChartData], geo: GeometryProxy) -> Int? {
        let x = location.x - geo[proxy.plotAreaFrame].origin.x
        let points = data.enumerated().compactMap { (i, item) -> (Int, CGFloat)? in
            let xValue = chartMode == .days ? item.date : firstDayOfMonth(for: item.date)
            guard let pos = proxy.position(forX: xValue) else { return nil }
            return (i, pos)
        }
        let nearest = points.min(by: { abs($0.1 - x) < abs($1.1 - x) })
        return nearest?.0
    }
}

struct ChartPopupView: View {
    let item: BalanceChartData
    let mode: ChartMode
    var body: some View {
        VStack(spacing: 4) {
            Text(mode == .days ? item.date.formatted(date: .abbreviated, time: .omitted) : item.date.formatted(.dateTime.month().year()))
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(item.balance, format: .number.precision(.fractionLength(0)))")
                .font(.headline)
                .foregroundColor(item.balance >= 0 ? .green : .red)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)).shadow(radius: 4))
    }
}

#Preview {
    let now = Date()
    let data = (0..<30).map { i in
        BalanceChartData(date: Calendar.current.date(byAdding: .day, value: -29 + i, to: now)!, balance: Decimal(Int.random(in: -10000...20000)))
    }
    let monthly = (0..<24).map { i in
        BalanceChartData(date: Calendar.current.date(byAdding: .month, value: -23 + i, to: now)!, balance: Decimal(Int.random(in: -10000...20000)))
    }
    return BalanceChartView(data: data, monthlyData: monthly)
}

