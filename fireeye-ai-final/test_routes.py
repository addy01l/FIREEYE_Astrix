
from route_optimizer import shortest_route


print("\nFIRE EYE - ROUTE OPTIMIZER EDGE TESTS")
print("=" * 50)


graph = {
    "Base": {
        "Village_A": 5,
        "Village_B": 10
    },
    "Village_A": {
        "Base": 5,
        "Village_B": 3,
        "Hospital": 8
    },
    "Village_B": {
        "Base": 10,
        "Village_A": 3,
        "Hospital": 4
    },
    "Hospital": {
        "Village_A": 8,
        "Village_B": 4
    }
}


# TEST 1: Unknown starting location

try:
    shortest_route(graph, "Unknown", "Hospital")

except ValueError as error:
    print("\nTEST 1 - Unknown Start: PASSED")
    print(error)


# TEST 2: Unknown destination

try:
    shortest_route(graph, "Base", "Unknown")

except ValueError as error:
    print("\nTEST 2 - Unknown Destination: PASSED")
    print(error)


# TEST 3: All roads blocked

result = shortest_route(
    graph,
    "Base",
    "Hospital",
    blocked_roads=[
        ("Base", "Village_A"),
        ("Base", "Village_B")
    ]
)

if result["success"] is False:
    print("\nTEST 3 - All Roads Blocked: PASSED")
    print(result)


# TEST 4: Same starting point and destination

result = shortest_route(graph, "Base", "Base")

if result["success"] and result["total_distance"] == 0:
    print("\nTEST 4 - Same Start and Destination: PASSED")
    print(result)


print("\nROUTE EDGE TESTING COMPLETED")
