
import heapq
import math


def shortest_route(graph, start, destination, blocked_roads=None):

    if start not in graph:
        raise ValueError(f"Unknown starting location: {start}")

    if destination not in graph:
        raise ValueError(f"Unknown destination: {destination}")

    blocked_roads = blocked_roads or []

    blocked = {
        frozenset(road) for road in blocked_roads
    }

    distances = {node: math.inf for node in graph}
    previous = {node: None for node in graph}

    distances[start] = 0

    priority_queue = [(0, start)]

    while priority_queue:

        current_distance, current_node = heapq.heappop(
            priority_queue
        )

        if current_distance > distances[current_node]:
            continue

        if current_node == destination:
            break

        for neighbor, road_distance in graph[current_node].items():

            if neighbor not in graph:
                raise ValueError(f"Unknown road destination: {neighbor}")

            if road_distance < 0 or not math.isfinite(road_distance):
                raise ValueError("Road distances must be finite and non-negative")

            if frozenset((current_node, neighbor)) in blocked:
                continue

            new_distance = current_distance + road_distance

            if new_distance < distances[neighbor]:

                distances[neighbor] = new_distance
                previous[neighbor] = current_node

                heapq.heappush(
                    priority_queue,
                    (new_distance, neighbor)
                )

    if distances[destination] == math.inf:

        return {
            "success": False,
            "message": "No available route found"
        }

    route = []
    current = destination

    while current is not None:
        route.append(current)
        current = previous[current]

    route.reverse()

    return {
        "success": True,
        "route": route,
        "total_distance": distances[destination]
    }


if __name__ == "__main__":

    road_network = {

        "Rescue_Base": {
            "Village_A": 4,
            "Village_B": 2
        },

        "Village_A": {
            "Rescue_Base": 4,
            "Village_B": 1,
            "Village_C": 5
        },

        "Village_B": {
            "Rescue_Base": 2,
            "Village_A": 1,
            "Village_C": 8,
            "Village_D": 10
        },

        "Village_C": {
            "Village_A": 5,
            "Village_B": 8,
            "Village_D": 2,
            "Hospital": 9
        },

        "Village_D": {
            "Village_B": 10,
            "Village_C": 2,
            "Hospital": 3
        },

        "Hospital": {
            "Village_C": 9,
            "Village_D": 3
        }
    }

    print("\nFIRE EYE - RESCUE ROUTE OPTIMIZER")
    print("=" * 45)

    print("\nTEST 1: Normal Route")

    result = shortest_route(
        road_network,
        "Rescue_Base",
        "Hospital"
    )

    print(result)

    print("\nTEST 2: Road Blocked")

    result = shortest_route(
        road_network,
        "Rescue_Base",
        "Hospital",
        blocked_roads=[("Village_C", "Village_D")]
    )

    print(result)

    print("\nTEST 3: All Roads From Base Blocked")

    result = shortest_route(
        road_network,
        "Rescue_Base",
        "Hospital",
        blocked_roads=[
            ("Rescue_Base", "Village_A"),
            ("Rescue_Base", "Village_B")
        ]
    )

    print(result)
