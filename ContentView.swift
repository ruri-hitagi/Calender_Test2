//
//  ContentView.swift
//  Calender_Test2
//
//  Created by みゆ on 2024/03/08.
//

import SwiftUI

//Extensions 拡張機能
extension Calendar {
    // 月の初日を取得
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }

    // 月に含まれる日数を取得
    func daysInMonth(for date: Date) -> Int? {
        return self.range(of: .day, in: .month, for: date)?.count
    }

    func weeksInMonth(for date: Date) -> Int? {
        return self.range(of: .weekOfMonth, in: .month, for: date)?.count
    }

    func weekday(for date: Date) -> Int? {
        return self.component(.weekday, from: date)
    }

    func day(for date: Date) -> Int? {
        return self.component(.day, from: date)
    }
}

// Data Models (データモデル)
struct CalendarDate: Identifiable {
    let id: UUID = UUID() // UUID型のプロパティをIdentifiableに準拠させる
    var date: Date?
    var isToday: Bool // 今日の日付かどうかを表すプロパティ
    var holidayName: String? // 祝日の名前を格納するプロパティ
}
// Identifiableプロトコルに準拠するための独自の型を定義する
struct IdentifiableUUID: Identifiable {
    var id: UUID // UUID型のidプロパティを定義する
    // 初期化メソッドを追加する
    init(id: UUID) {
        self.id = id
    }
}

//　CalendarViewModel (カレンダービューモデル)
class CalendarViewModel: ObservableObject {
    @Published var weekdays = [String]()
    @Published var calendarDates: [CalendarDate] = []
    @Published var selectedMonth: Date = Date()
    
    init(selectedDateUUID: UUID) {
        setupCalendar(for: selectedMonth)
    }
    
    //カレンダーのセットアップ
    func setupCalendar(for month: Date) {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.startOfMonth(for: month),
              let daysInMonth = calendar.daysInMonth(for: month) else {
            return
        }

        // カレンダーの日付を設定
        var days = [CalendarDate]()
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                let isToday = calendar.isDateInToday(date) // 今日の日付かどうか確認
                days.append(CalendarDate(date: date, isToday: isToday))
            }
        }

        // 初週のオフセット
        if let firstDate = days.first?.date, let firstDateWeekday = calendar.weekday(for: firstDate) {
            let firstWeekEmptyDays = firstDateWeekday - 1
            for _ in 0..<firstWeekEmptyDays {
                days.insert(CalendarDate(date: nil, isToday: false), at: 0)
            }
        }

        // 最終週のオフセット
        if let lastDate = days.last?.date, let lastDateWeekday = calendar.weekday(for: lastDate) {
            let lastWeekEmptyDays = 7 - lastDateWeekday
            for _ in 0..<lastWeekEmptyDays {
                days.append(CalendarDate(date: nil, isToday: false))
            }
        }

        // カレンダーの日付を更新
        calendarDates = days
    }

            
            
            func changeMonth(by offset: Int) {
                if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) {
                    selectedMonth = newMonth
                    setupCalendar(for: newMonth)
                }
            }
            
            
            //祝日かどうかを判定する関数
            func isHoliday(date: Date) -> Bool {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
                guard let year = components.year, let month = components.month,
                      let day = components.day,
                      let weekday = components.weekday else{
                    return false
                }
                
                //日曜日かどうかを判定
                if weekday == 1 {
                    return true
                }
                
                //国民の休日の判定
                if weekday == 2 && day == 12 && month == 2 {
                    return true // 2月11日が祝日の場合、2月12日も国民の休日となる
                } else if weekday == 2 && day == 11 && month == 5 {
                    return true // 5月3日と5月4日の間に祝日がある場合、その間も国民の休日となる
                } else if weekday == 2 && day == 4 && month == 5 {
                    let dateComponents = DateComponents(year: year, month: month, day: 3)
                    if let previousDay = calendar.date(from: dateComponents), calendar.isDate(previousDay, inSameDayAs: date) {
                        return true
                    }
                }else if month == 1 && day == 1 {
                    return true // 元日
                }else if month == 2 && day == 23{
                    return true //天皇誕生日
                }else if month == 4 && day == 29{
                    return true //昭和の日
                }else if month == 5 && day == 3{
                    return true //憲法記念日
                }else if month == 5 && day == 4{
                    return true //みどりの日
                }else if month == 5 && day == 5{
                    return true //こどもの日
                } else if month == 8 && day == 11 {
                    return true // 山の日
                } else if month == 11 && day == 3 {
                    return true // 文化の日
                } else if month == 11 && day == 23 {
                    return true// 勤労感謝の日
                }
                
                // ハッピーマンデー法に基づく祝日の計算
                else if weekday == 2{
                    // 月曜日の場合
                    switch month {
                    case 1: // 成人の日（1月の第2月曜日）
                        if day > 7 && day <= 14 {
                            return true
                        }
                    case 7: // 海の日（7月の第3月曜日）
                        if day > 14 && day <= 21 {
                            return true
                        }
                    case 9: // 敬老の日（9月の第3月曜日）
                        if day > 14 && day <= 21 {
                            return true
                        }
                    case 10: // 体育の日（10月の第2月曜日）
                        if day > 7 && day <= 14 {
                            return true
                        }
                    default:
                        return false
                    }
                }
                
                // 春分の日と秋分の日の計算
                else if month == 3 {
                    // 春分の日
                    if day == calculateSpringAutumnEquinox(year: currentYear(), isSpring: true) {
                        return true
                    }
                } else if month == 9 {
                    // 秋分の日
                    if day == calculateSpringAutumnEquinox(year: currentYear(), isSpring: false) {
                        return true
                    }
                }
                
                func currentYear() -> Int {
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: Date())
                    return year
                }
                
                func calculateSpringAutumnEquinox(year: Int, isSpring: Bool) -> Int? {
                    let calendar = Calendar.current
                    var components = DateComponents()
                    components.year = year
                    components.month = 3 // 春分の日は3月または9月にあるため、適切な月を設定する必要があります
                    if isSpring {
                        components.day = 20 // 春分の日は3月20日以降
                    } else {
                        components.day = 23 // 秋分の日は9月23日以降
                    }
                    
                    guard let springDate = calendar.date(from: components) else {
                        return nil
                    }
                    
                    return calendar.component(.day, from: springDate)
                }
                
                //他の祝日の判定処理
                return false
            }
        }

    
    //祝日かどうかを判定する関数
    func isHolidayName(date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let year = components.year, let month = components.month, let day = components.day,
              let weekday = components.weekday else{
            return nil
        }
        
        //春分の日と秋分の日の計算
        func calculateSpringAutumnEquinox(year: Int, isSpring: Bool) -> Int? {
            var components = DateComponents()
            components.year = year
            components.month = 3 //春分の日は3月または9月にあるため、適切な月を設定する必要があります
            if isSpring {
                components.day = 20 // 春分の日は3月20日以降
            } else {
                components.day = 23 // 秋分の日は9月23日以降
            }
            
            guard let springDate = calendar.date(from: components) else {
                return nil
            }
            
            return calendar.component(.day, from: springDate)
        }
        
        //国民の休日の判定
        if weekday == 2 && day == 12 && month == 2 {
            return "振替休日" // 2月11日が祝日の場合、2月12日も国民の休日となる
        } else if weekday == 2 && day == 11 && month == 5 {
            return "振替休日" // 5月3日と5月4日の間に祝日がある場合、その間も国民の休日となる
        } else if weekday == 2 && day == 4 && month == 5 {
            let dateComponents = DateComponents(year: year, month: month, day: 3)
            if let previousDay = calendar.date(from: dateComponents), calendar.isDate(previousDay, inSameDayAs: date) {
                return "振替休日"
            }
        }else if month == 1 && day == 1 {
            return "元日" // 元日
        }else if month == 2 && day == 23{
            return "天皇誕生日" //天皇誕生日
        }else if month == 4 && day == 29{
            return "昭和の日" //昭和の日
        }else if month == 5 && day == 3{
            return "憲法記念日" //憲法記念日
        }else if month == 5 && day == 4{
            return "みどりの日" //みどりの日
        }else if month == 5 && day == 5{
            return "こどもの日" //こどもの日
        } else if month == 8 && day == 11 {
            return "山の日" // 山の日
        } else if month == 11 && day == 3 {
            return "文化の日" // 文化の日
        } else if month == 11 && day == 23 {
            return "勤労感謝の日"// 勤労感謝の日
        }
        
        // ハッピーマンデー法に基づく祝日の計算
        else if weekday == 2{
            // 月曜日の場合
            switch month {
            case 1: // 成人の日（1月の第2月曜日）
                if day > 7 && day <= 14 {
                    return "成人の日"
                }
            case 7: // 海の日（7月の第3月曜日）
                if day > 14 && day <= 21 {
                    return "海の日"
                }
            case 9: // 敬老の日（9月の第3月曜日）
                if day > 14 && day <= 21 {
                    return "敬老の日"
                }
            case 10: // 体育の日（10月の第2月曜日）
                if day > 7 && day <= 14 {
                    return "体育の日"
                }
            default:
                return nil
            }
        }
        // 春分の日と秋分の日の計算
        else if month == 3 {
            // 春分の日
            if day == calculateSpringAutumnEquinox(year: year, isSpring: true) {
                return "春分の日"
            }
        } else if month == 9 {
            // 秋分の日
            if day == calculateSpringAutumnEquinox(year: year, isSpring: false) {
                return "秋分の日"
            }
        }
        
        // ハッピーマンデー法とその他の祝日の計算で該当しない場合、nilを返す
        return nil
    }


//親ビュー
struct ContentView: View {
    @ObservedObject var viewModel = CalendarViewModel(selectedDateUUID: UUID())
    @State private var selectedDateUUID: IdentifiableUUID? = nil
    
    var body: some View{
        CalendarView(viewModel: viewModel, selectedDateUUID: $selectedDateUUID)
            .onAppear{
                selectedDateUUID = IdentifiableUUID(id: UUID())
            }
    }
    
    // カレンダービュー
    struct CalendarView: View {
        @StateObject var viewModel: CalendarViewModel
        @Binding var selectedDateUUID: IdentifiableUUID?
        @State private var isSheetPresented = false
        
        let columns: [GridItem] = Array(repeating: .init(.fixed(40)), count: 7)
        
        var body: some View {
            VStack {
                Text("\(viewModel.selectedMonth, formatter: monthFormatter)")
                    .font(.title)
                    .padding()
                
                HStack {
                    ForEach(viewModel.weekdays, id: \.self) { weekday in
                        Text(weekday).frame(width: 40, height: 40, alignment: .center)
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.calendarDates) { calendarDate in
                        CalendarDateView(calendarDate: calendarDate, viewModel: viewModel, selectedDateUUID: $selectedDateUUID, isSheetPresented: $isSheetPresented)
                    }
                }
                
                HStack {
                    Button("前の月") {
                        viewModel.changeMonth(by: -1)
                    }
                    Spacer()
                    Button("次の月") {
                        viewModel.changeMonth(by: 1)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $isSheetPresented) {
                // CalendarDetailSheet への実装が必要です
            }
        }
        
        private var monthFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy MMMM"
            return formatter
        }
    }
    
    struct CalendarDateView: View {
        var calendarDate: CalendarDate
        @ObservedObject var viewModel: CalendarViewModel
        @Binding var selectedDateUUID: IdentifiableUUID?
        @Binding var isSheetPresented: Bool
        
        var body: some View {
            Button(action: {
                selectedDateUUID = IdentifiableUUID(id: calendarDate.id)
                isSheetPresented = true
            }) {
                Text("\(calendarDate.date ?? Date(), formatter: dayFormatter)")
                    .foregroundColor(calendarDate.isToday ? .blue : .black)
                    .background(calendarDate.isToday ? Color.yellow : Color.clear)
                    .cornerRadius(5)
            }
        }
        
        private var dayFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            return formatter
        }
    }
}
