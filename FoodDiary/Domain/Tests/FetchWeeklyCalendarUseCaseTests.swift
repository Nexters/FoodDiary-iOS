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

    @Test("기록된 날짜는 hasRecord가 true")
    func testRecordedDatesMarkedCorrectly() async throws {
        let mockRepository = MockFoodRecordRepository()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        mockRepository.recordedDatesToReturn = [today]

        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)
        let result = try await useCase.execute(for: today)

        let todayData = result.first { calendar.isDate($0.date, inSameDayAs: today) }
        #expect(todayData?.hasRecord == true)
    }

    @Test("미기록 날짜는 hasRecord가 false")
    func testUnrecordedDatesMarkedCorrectly() async throws {
        let mockRepository = MockFoodRecordRepository()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 빈 기록
        mockRepository.recordedDatesToReturn = []

        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)
        let result = try await useCase.execute(for: today)

        let allHasRecordFalse = result.allSatisfy { !$0.hasRecord }
        #expect(allHasRecordFalse)
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

    // MARK: - previousWeek() / nextWeek() Tests

    @Test("이전 주는 7일 전")
    func testPreviousWeekIsSevenDaysBefore() {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)
        let calendar = Calendar.current

        let today = Date()
        let previousWeek = useCase.previousWeek(from: today)

        let daysDifference = calendar.dateComponents([.day], from: previousWeek, to: today).day
        #expect(daysDifference == 7)
    }

    @Test("다음 주는 7일 후")
    func testNextWeekIsSevenDaysAfter() {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)
        let calendar = Calendar.current

        let today = Date()
        let nextWeek = useCase.nextWeek(from: today)

        let daysDifference = calendar.dateComponents([.day], from: today, to: nextWeek).day
        #expect(daysDifference == 7)
    }

    // MARK: - formatMonthText() Tests

    @Test("월 텍스트 포맷이 올바름")
    func testMonthTextFormat() {
        let mockRepository = MockFoodRecordRepository()
        let useCase = FetchWeeklyCalendarUseCase(repository: mockRepository)

        // 1월 날짜 생성
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        let januaryDate = Calendar.current.date(from: components)!

        let monthText = useCase.formatMonthText(for: januaryDate)
        #expect(monthText == "1월")
    }
}
