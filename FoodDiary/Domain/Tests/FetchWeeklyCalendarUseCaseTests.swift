//
//  FetchWeeklyCalendarUseCaseTests.swift
//  Domain
//

@testable import Domain
import Foundation
import Testing

@Suite("FetchWeeklyCalendarUseCase Tests")
struct FetchWeeklyCalendarUseCaseTests {

    // MARK: - execute() Tests

    @Test("주간 데이터는 항상 7일을 반환")
    func testWeeklyDataHasSevenDays() async throws {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)

        let result = try await useCase.execute(for: Date())

        #expect(result.count == 7)
    }

    @Test("기록된 날짜는 records가 비어있지 않음")
    func testRecordedDatesMarkedCorrectly() async throws {
        let mockRepository = MockFoodRecordRepository()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let mockRecord = FoodRecord(id: "1", date: today, imageURLs: [], createdAt: today)
        mockRepository.recordsByDateToReturn = [today: [mockRecord]]

        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)
        let result = try await useCase.execute(for: today)

        let todayData = result.first { calendar.isDate($0.date, inSameDayAs: today) }
        #expect(todayData?.records.isEmpty == false)
    }

    @Test("미기록 날짜는 records가 비어있음")
    func testUnrecordedDatesMarkedCorrectly() async throws {
        let mockRepository = MockFoodRecordRepository()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 빈 기록
        mockRepository.recordsByDateToReturn = [:]

        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)
        let result = try await useCase.execute(for: today)

        let allRecordsEmpty = result.allSatisfy { $0.records.isEmpty }
        #expect(allRecordsEmpty)
    }

    @Test("오늘 날짜는 isToday가 true")
    func testTodayMarkedCorrectly() async throws {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)

        let result = try await useCase.execute(for: Date())

        let todayCount = result.filter { $0.isToday }.count
        #expect(todayCount == 1)
    }

    @Test("요일 포맷이 올바름")
    func testDayOfWeekFormat() async throws {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)

        let result = try await useCase.execute(for: Date())

        // 한국어 요일 확인 (일, 월, 화, 수, 목, 금, 토)
        let validDays = ["일", "월", "화", "수", "목", "금", "토"]
        let allValid = result.allSatisfy { validDays.contains($0.dayOfWeek) }
        #expect(allValid)
    }

    @Test("날짜 번호는 2자리 포맷")
    func testDayNumberFormat() async throws {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)

        let result = try await useCase.execute(for: Date())

        let allTwoDigits = result.allSatisfy { $0.dayNumber.count == 2 }
        #expect(allTwoDigits)
    }

    // MARK: - Calendar Extension Tests

    @Test("이전 주는 7일 전")
    func testPreviousWeekIsSevenDaysBefore() {
        let calendar = Calendar.current

        let today = Date()
        let previousWeek = calendar.previousWeek(from: today)

        let daysDifference = calendar.dateComponents([.day], from: previousWeek, to: today).day
        #expect(daysDifference == 7)
    }

    @Test("다음 주는 7일 후")
    func testNextWeekIsSevenDaysAfter() {
        let calendar = Calendar.current

        let today = Date()
        let nextWeek = calendar.nextWeek(from: today)

        let daysDifference = calendar.dateComponents([.day], from: today, to: nextWeek).day
        #expect(daysDifference == 7)
    }

    // MARK: - Date Extension Tests

    @Test("월 텍스트 포맷이 올바름")
    func testMonthTextFormat() {
        // 1월 날짜 생성
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        let januaryDate = Calendar.current.date(from: components)!

        let monthText = januaryDate.formatMonthText()
        #expect(monthText == "1월")
    }
}
