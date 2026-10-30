import Testing
@testable import EverfitTest

struct WorkoutDTOTests {
    @Test func decodesAndMapsToDomain() throws {
        let days = try Fixtures.response().data.map { $0.toDomain() }

        #expect(days.count == 3)
        #expect(days[0].weekday == 0)
        #expect(days[0].workouts.first?.title == "Legs day")
        #expect(days[0].workouts.first?.exerciseCount == 5)
        #expect(days[0].workouts.first?.isCompleted == false)   // API status 1 = missed
        #expect(days[1].workouts.first?.isCompleted == true)
        #expect(days[2].workouts.isEmpty)
    }

    @Test func unknownStatusFallsBackToAssigned() {
        let dto = AssignmentDTO(id: "x", title: "X", status: 99, totalExercise: 1)
        #expect(dto.toDomain().isCompleted == false)
    }

    @Test func userCompletionWinsOverAPIStatus() {
        let completedByAPI = AssignmentDTO(id: "x", title: "X", status: WorkoutStatus.completed.rawValue, totalExercise: 1)

        #expect(completedByAPI.toDomain().isCompleted == true)
        #expect(completedByAPI.toDomain(userCompletion: false).isCompleted == false)
    }
}
