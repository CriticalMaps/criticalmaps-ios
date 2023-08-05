import Combine
import ComposableArchitecture
import ComposableCoreLocation
import Foundation
import Logger
import SharedDependencies
import SharedModels

// MARK: State

public struct NextRideFeature: Reducer {
  public init() {}
  
  @Dependency(\.nextRideService) public var service
  @Dependency(\.date) public var date
  @Dependency(\.mainQueue) public var mainQueue
  @Dependency(\.coordinateObfuscator) public var coordinateObfuscator
  @Dependency(\.isNetworkAvailable) public var isNetworkAvailable

  public struct State: Equatable {
    public init(nextRide: Ride? = nil) {
      self.nextRide = nextRide
    }

    public var nextRide: Ride?
    public var rideEvents: [Ride] = []
    public var rideEventSettings = RideEventSettings()

    public var userLocation: Coordinate?
  }

  // MARK: Actions

  public enum Action: Equatable {
    case getNextRide(Coordinate)
    case nextRideResponse(TaskResult<[Ride]>)
    case setNextRide(Ride)
  }

  // MARK: Reducer

  /// Reducer handling next ride feature actions
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case let .getNextRide(coordinate):
      guard state.rideEventSettings.isEnabled else {
        logger.debug("NextRide featue is disabled")
        return .none
      }

      let obfuscatedCoordinate = coordinateObfuscator.obfuscate(
        coordinate,
        .thirdDecimal
      )

      let requestRidesInMonth: Int = queryMonth(for: date.callAsFunction)

      return .run { [distance = state.rideEventSettings.eventDistance] send in
        await send(
          .nextRideResponse(
            TaskResult {
              try await service.nextRide(
                obfuscatedCoordinate,
                distance.rawValue,
                requestRidesInMonth
              )
            }
          )
        )
      }

    case let .nextRideResponse(.failure(error)):
      logger.error("Get next ride failed 🛑 with error: \(error)")
      return .none
    case let .nextRideResponse(.success(rides)):
      guard !rides.isEmpty else {
        logger.info("Rides array is empty")
        return .none
      }
      guard !rides.map(\.rideType).isEmpty else {
        logger.info("No upcoming events for filter selection rideType")
        return .none
      }
      let typeSettings = state.rideEventSettings.typeSettings
      state.rideEvents = rides.sortByDateAndFilterBeforeDate(date.callAsFunction)

      // Sort rides by date and pick the first one with a date greater than now
      let ride = rides // swiftlint:disable:this sorted_first_last
        .lazy
        .filter {
          guard let type = $0.rideType else { return true }
          return typeSettings.contains(where: { $0.key == type })
        }
        .filter(\.enabled)
        .sorted { lhs, rhs in
          let byDate = lhs.dateTime < rhs.dateTime

          guard
            let userLocation = state.userLocation,
            let lhsCoordinate = lhs.coordinate,
            let rhsCoordinate = rhs.coordinate
          else {
            return byDate
          }

          if Calendar.current.isDate(lhs.dateTime, inSameDayAs: rhs.dateTime) {
            return lhsCoordinate.distance(from: userLocation) < rhsCoordinate.distance(from: userLocation)
          } else {
            return byDate
          }
        }
        .first { ride in ride.dateTime > date() }

      guard let filteredRide = ride else {
        logger.info("No upcoming events after filter")
        return .none
      }

      return .send(.setNextRide(filteredRide))

    case let .setNextRide(ride):
      state.nextRide = ride
      return .none
    }
  }
}

// MARK: Helper

enum EventError: Error, LocalizedError {
  case eventsAreNotEnabled
  case invalidDateError
  case rideIsOutOfRangeError
  case noUpcomingRides
  case rideTypeIsFiltered
  case rideDisabled
}

private func queryMonth(for date: () -> Date = Date.init, calendar: Calendar = .current) -> Int {
  let currentMonthOfFallback = calendar.dateComponents([.month], from: date()).month ?? 0

  guard !calendar.isDateInWeekend(date()) else { // current date is on a weekend
    return currentMonthOfFallback
  }

  guard let startDateOfNextWeekend = calendar.nextWeekend(startingAfter: date())?.start else {
    return currentMonthOfFallback
  }
  guard let month = calendar.dateComponents([.month], from: startDateOfNextWeekend).month else {
    return currentMonthOfFallback
  }

  return max(currentMonthOfFallback, month)
}

public extension Array where Element == Ride {
  func sortByDateAndFilterBeforeDate(_ now: () -> Date) -> Self {
    lazy
      .sorted(by: \.dateTime)
      .filter { $0.dateTime > now() }
  }
}

extension SharedModels.Coordinate {
  init(_ location: ComposableCoreLocation.Location) {
    self = .init(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude
    )
  }
}
