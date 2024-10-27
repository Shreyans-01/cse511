from neo4j import GraphDatabase

class Interface:
    def __init__(self, uri, user, password):
        self._driver = GraphDatabase.driver(uri, auth=(user, password), encrypted=False)
        self._driver.verify_connectivity()

    def close(self):
        self._driver.close()

    def pagerank(self, max_iterations, weight_property):
        with self._driver.session() as session:
            # First, project the graph
            session.run("""
                CALL gds.graph.project(
                    'myGraph',
                    'Location',
                    'TRIP',
                    {
                        relationshipProperties: $weight
                    }
                )
            """, weight=weight_property)

            # Run PageRank
            result = session.run("""
                CALL gds.pageRank.stream('myGraph', {
                    maxIterations: $max_iter,
                    dampingFactor: 0.85,
                    relationshipWeightProperty: $weight
                })
                YIELD nodeId, score
                WITH gds.util.asNode(nodeId) AS node, score
                ORDER BY score DESC
                RETURN node.name AS name, score
            """, max_iter=max_iterations, weight=weight_property)
            
            # Get all results
            all_results = result.data()
            
            # Clean up the projected graph
            session.run("CALL gds.graph.drop('myGraph')")
            
            # Return the highest and lowest ranked nodes
            return [all_results[0], all_results[-1]]

    def bfs(self, start_node, target_nodes):
        with self._driver.session() as session:
            # Project the graph for BFS
            session.run("""
                CALL gds.graph.project(
                    'bfsGraph',
                    'Location',
                    'TRIP'
                )
            """)

            # Run BFS
            result = session.run("""
                MATCH (source:Location {name: $start})
                MATCH (target:Location {name: $end})
                CALL gds.bfs.stream('bfsGraph', {
                    sourceNode: source,
                    targetNodes: [target]
                })
                YIELD path
                RETURN [node in nodes(path) | {
                    name: node.name
                }] AS path
                LIMIT 1
            """, start=start_node, end=target_nodes)

            # Get the result
            paths = result.data()
            
            # Clean up the projected graph
            session.run("CALL gds.graph.drop('bfsGraph')")
            
            return paths
