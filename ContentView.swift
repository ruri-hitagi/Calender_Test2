//
//  ContentView.swift
//  Calender_Test2
//
//  Created by みゆ on 2024/03/08.
//

import SwiftUI

//Extensions 拡張機能
extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
    
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

//Models　モデル
// 日付を表す構造体
struct CalendarDate: Identifiable {
    var id = UUID() // UUID型のプロパティをIdentifiableに準拠させる
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

//　カレンダービューモデル
class CalendarViewModel: ObservableObject {
    @Published var calendarDates = [CalendarDate]()
    @Published var weekdays = [String]()
    @Published var selectedMonth = Date()
    
    init(selectedDateUUID: UUID){
        // ここでselectedDateUUIDを使う必要があるか確認する
        setupCalendar()
    }
    
    //カレンダーのセットアップ
    func setupCalendar() {
        print("setupCalendar")
        
        // 曜日の設定
        let dateFormatter = DateFormatter()
        weekdays = dateFormatter.shortWeekdaySymbols
        
        //今月の日付を取得
        let now = Date()
        guard let startOfMonth = Calendar.current.startOfMonth(for: now),
              let daysInMonth = Calendar.current.daysInMonth(for: now),
              let weeksInMonth = Calendar.current.weeksInMonth(for: now) else {
            return
        }
        
        var days = [CalendarDate] ()
        
        //カレンダーの日付を設定
        for day in 0..<daysInMonth {
            if let date = Calendar.current.date(byAdding: .day, value: day, to: startOfMonth){
                let isToday = Calendar.current.isDateInToday(date) //今日の日付かどうか確認
                days.append(CalendarDate(date: date, isToday: isToday))
            }
        }
        
        //初週のオフセット
        if let firstDay = days.first, let firstDate = firstDay.date,
           let firstDateWeekday = Calendar.current.weekday(for: firstDate) {
            let firstWeekEmptyDays = firstDateWeekday - 1
            for _ in 0..<firstWeekEmptyDays {
                days.insert(CalendarDate(date: nil, isToday: false),at: 0)
            }
        }
        
        //最終週のオフセット
        if let lastDay = days.last, let lastDate = lastDay.date,
           let lastDateWeekday = Calendar.current.weekday(for: lastDate) {
            let lastWeekdayEmptyDays = 7 - lastDateWeekday
            for _ in 0..<lastWeekdayEmptyDays {
                days.append(CalendarDate(date:nil ,isToday: false))
            }
        }
        
        //カレンダーの日付を更新
        calendarDates = days
    }
    
    //祝日かどうかを判定する関数
    func isHoliday(date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let year = components.year, let month = components.month, let day = components.day,
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
            return true // 勤労感謝の日
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

//親ビュー
struct ContentView: View {
    @ObservedObject var viewModel: CalendarViewModel = CalendarViewModel(selectedDateUUID: UUID())
    @State private var selectedDateUUID: IdentifiableUUID? = nil
    
    var body: some View{
        CalendarView(viewModel: viewModel, selectedDateUUID: $selectedDateUUID)
            .onAppear{
                selectedDateUUID = IdentifiableUUID(id: UUID())
            }
    }
}

// カレンダービュー
struct CalendarView: View {
    @StateObject var viewModel: CalendarViewModel
    @Binding var selectedDateUUID: IdentifiableUUID? // 選択された日付の IdentifiableUUID を追跡するための Binding
    @State private var isSheetPresented = false // シートの表示状態を追跡するプロパティを追加
    
    let columns: [GridItem] = Array(repeating: .init(.fixed(40)), count: 7)
    @State private var selectedDate:Date?
    
    var body: some View {
        VStack{
            // 西暦と月の表示
            Text(formattedDate)
                .font(.title)
            
            // 曜日
            HStack {
                ForEach(viewModel.weekdays, id: \.self) { weekday in
                    Text(weekday).frame(width: 40, height: 40, alignment: .center)
                }
            }
            
            //カレンダー
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.calendarDates) { calendarDate in
                    if let date = calendarDate.date, let day = Calendar.current.day(for: date){
                        let isHoliday = viewModel.isHoliday(date: date)//祝日かどうかを確認
                        Button(action: {
                            selectedDate = date //選択された日付を更新
                        }){
                            Text("\(day)").frame(width: 40, height: 40, alignment: .center)
                        }
                        .foregroundColor(isHoliday ? .red : calendarDate.isToday ? .blue : .black) // 今日の日付は青く、祝日は赤く表示
                        .padding(5)
                        .background(selectedDate == calendarDate.date ? Color.yellow : Color.clear)
                        .cornerRadius(5)
                    }else {
                            Text("").frame(width: 40, height: 40, alignment: .center)
                        }
                    }
                }
            }
            .padding()
        }
            // フォーマットされた日付
            var formattedDate: String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM"
                return dateFormatter.string(from: viewModel.selectedMonth)
            }
        }
