/// `GET /workouts` — the current week's workouts.
nonisolated struct WorkoutsRequest: APIRequest {
    typealias Response = APIResponse<[DayDTO]>

    let path = APIConstants.Path.workouts
}
