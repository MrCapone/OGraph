//
//  OGraphTests.m
//  OGraphTests
//
//  Created by Matthew McGlincy on 5/6/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "GraphEdge.h"
#import "GraphNode.h"
#import "GraphSearchAStar.h"
#import "GraphSearchBFS.h"
#import "GraphSearchDFS.h"
#import "GraphSearchDijkstra.h"
#import "Heuristic.h"
#import "HeuristicEuclid.h"
#import "HeuristicManhattan.h"
#import "NavGraphNode.h"
#import "SparseGraph.h"
#import "OGraphTests.h"

@interface OGraphTests()
+ (SparseGraph *)minimalDigraph;
+ (SparseGraph *)minimalNavGraph;
+ (SparseGraph *)sampleUndirectedGraph;
+ (SparseGraph *)twoRouteCostedDigraph;
+ (SparseGraph *)complicatedCostedDigraph;
+ (SparseGraph *)threeByThreeNavGraph;
- (void)aStarWithHeuristic:(id<Heuristic>)heuristic;
@end

@implementation OGraphTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

+ (SparseGraph *)minimalDigraph {
    // simple digraph with 2 nodes and 1 edge
    SparseGraph *graph = [[SparseGraph alloc] initWithIsDigraph:YES];
    [graph addNodeWithIndex:0];
    [graph addNodeWithIndex:1];
    [graph addEdgeFrom:0 to:1];
    return graph;
}

+ (SparseGraph *)minimalNavGraph {
    SparseGraph *graph = [[SparseGraph alloc] initWithIsDigraph:NO];
    NavGraphNode *node1 = [[NavGraphNode alloc] initWithIndex:0 x:0 y:0];
    NavGraphNode *node2 = [[NavGraphNode alloc] initWithIndex:1 x:200.0 y:200.0];
    [graph addNode:node1];
    [graph addNode:node2];
    [graph addEdgeFrom:0 to:1];
    return graph;
}

- (void)testSparseGraph {
    SparseGraph *graph = [OGraphTests minimalDigraph];
    
    // simple existence checks
    XCTAssertEqual(graph.numNodes, 2U);
    XCTAssertEqual(graph.numActiveNodes, 2U);
    XCTAssertEqual(graph.numEdges, 1U);
    XCTAssertTrue([graph isNodePresentWithIndex:0]);
    XCTAssertTrue([graph isNodePresentWithIndex:1]);
    XCTAssertFalse([graph isNodePresentWithIndex:3]);
    XCTAssertTrue([graph isEdgePresentWithFrom:0 to:1]);    
    XCTAssertFalse([graph isEdgePresentWithFrom:1 to:0]);    
    
    // remove an edge
    [graph removeEdgeWithFrom:0 to:1];
    XCTAssertEqual(graph.numEdges, 0U);
    XCTAssertFalse([graph isEdgePresentWithFrom:0 to:1]);    
    XCTAssertEqual(graph.numEdges, 0U);
    
    // put it back
    GraphEdge *e0 = [[GraphEdge alloc] initWithFrom:0 to:1];
    [graph addEdge:e0];
    XCTAssertTrue([graph isEdgePresentWithFrom:0 to:1]);    
    XCTAssertEqual(graph.numEdges, 1U);
    
    // remove a node, which should only deactivate the node
    [graph removeNodeWithIndex:1];
    XCTAssertEqual(graph.numNodes, 2U);
    XCTAssertEqual(graph.numActiveNodes, 1U);
    // but, it should nuke our edge, too
    XCTAssertEqual(graph.numEdges, 0U);
    XCTAssertFalse([graph isEdgePresentWithFrom:0 to:1]);    
    
    // clear
    [graph clear];
    XCTAssertEqual(graph.numNodes, 0U);
    XCTAssertEqual(graph.numActiveNodes, 0U);
    XCTAssertEqual(graph.numEdges, 0U);
    XCTAssertFalse([graph isNodePresentWithIndex:0]);
    XCTAssertFalse([graph isNodePresentWithIndex:1]);
    XCTAssertFalse([graph isEdgePresentWithFrom:0 to:1]);    
}

- (void)testSimpleDirectedDFS {
    // simple digraph with 2 nodes and 1 edge
    SparseGraph *graph = [OGraphTests minimalDigraph];
    
    GraphSearchDFS *dfs = [[GraphSearchDFS alloc] initWithGraph:graph sourceNodeIndex:0 targetNodeIndex:1];
    XCTAssertTrue(dfs.pathToTargetFound);
    NSArray *path = [dfs getPathToTarget];
    // path should be of 2 elements, from node 0 (source) to node 1 (target)
    XCTAssertEqual([path count], 2U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:0]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:1]);
    
}

+ (SparseGraph *)sampleUndirectedGraph {
    // create the undirected graph from The Secret Life of Graphs chapter
    SparseGraph *graph = [[SparseGraph alloc] initWithIsDigraph:NO];
    [graph addNodeWithIndex:0];
    [graph addNodeWithIndex:1];
    [graph addNodeWithIndex:2];
    [graph addNodeWithIndex:3];
    [graph addNodeWithIndex:4];
    [graph addNodeWithIndex:5];
    [graph addEdgeFrom:0 to:1];
    [graph addEdgeFrom:0 to:2];
    [graph addEdgeFrom:1 to:4];
    [graph addEdgeFrom:2 to:3];
    [graph addEdgeFrom:3 to:4];
    [graph addEdgeFrom:3 to:5];
    [graph addEdgeFrom:4 to:5];
    return graph;
}

- (void)testUndirectedDFS {
    SparseGraph *graph = [OGraphTests sampleUndirectedGraph];
    GraphSearchDFS *dfs = [[GraphSearchDFS alloc] initWithGraph:graph sourceNodeIndex:4 targetNodeIndex:2];
    
    XCTAssertTrue(dfs.pathToTargetFound);
    NSArray *path = [dfs getPathToTarget];
    // note that the order we add edges will affect the order edges are pushed 
    // onto our search stack, and thus ultimately the order of the DFS.
    // With the edge-adding order above, we end up with 4=>5=>3=>2
    XCTAssertEqual([path count], 4U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:4]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:5]);
    XCTAssertEqualObjects([path objectAtIndex:2], [NSNumber numberWithInt:3]);
    XCTAssertEqualObjects([path objectAtIndex:3], [NSNumber numberWithInt:2]);
    
}

- (void)testUndirectedBFS {
    SparseGraph *graph = [OGraphTests sampleUndirectedGraph];
    GraphSearchBFS *bfs = [[GraphSearchBFS alloc] initWithGraph:graph sourceNodeIndex:4 targetNodeIndex:2];
    
    XCTAssertTrue(bfs.pathToTargetFound);
    NSArray *path = [bfs getPathToTarget];
    // BFS path is 4=>3=>2
    XCTAssertEqual([path count], 3U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:4]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:3]);
    XCTAssertEqualObjects([path objectAtIndex:2], [NSNumber numberWithInt:2]);
    
}

+ (SparseGraph *)twoRouteCostedDigraph {
    // simple digraph with 4 nodes, with a "cheaper" way to get from
    // source n0 to target n3
    SparseGraph *graph = [[SparseGraph alloc] initWithIsDigraph:YES];
    [graph addNodeWithIndex:0];
    [graph addNodeWithIndex:1];
    [graph addNodeWithIndex:2];
    [graph addNodeWithIndex:3];
    [graph addEdgeFrom:0 to:1 cost:1.0];
    [graph addEdgeFrom:0 to:2 cost:1.0];
    [graph addEdgeFrom:1 to:3 cost:0.5];
    [graph addEdgeFrom:2 to:3 cost:1.0];
    return graph;
}

+ (SparseGraph *)complicatedCostedDigraph {
    // a more complicated digraph, as used in the chapter
    // The Secret Life of Graphs, pg233.
    SparseGraph *graph = [[SparseGraph alloc] initWithIsDigraph:YES];
    [graph addNodeWithIndex:0];
    [graph addNodeWithIndex:1];
    [graph addNodeWithIndex:2];
    [graph addNodeWithIndex:3];
    [graph addNodeWithIndex:4];
    [graph addNodeWithIndex:5];
    [graph addEdgeFrom:0 to:4 cost:2.9];
    [graph addEdgeFrom:0 to:5 cost:1.0];
    [graph addEdgeFrom:1 to:2 cost:3.1];
    [graph addEdgeFrom:2 to:4 cost:0.8];
    [graph addEdgeFrom:3 to:2 cost:3.7];
    [graph addEdgeFrom:4 to:1 cost:1.9];
    [graph addEdgeFrom:4 to:5 cost:3.0];
    [graph addEdgeFrom:5 to:3 cost:1.1];
    return graph;
}

- (void)testEasyDijkstra {
    SparseGraph *graph = [OGraphTests twoRouteCostedDigraph];
    GraphSearchDijkstra *dij = [[GraphSearchDijkstra alloc] initWithGraph:graph sourceNodeIndex:0 targetNodeIndex:3];
    NSArray *path = [dij getPathToTarget];
    // our test digraph has 2 routes from 0=>3: 0=>2=>3 costing 2.0, and 0=>1=>3 costing 1.5.
    // Make sure our search picks the cheaper route of 1.5.
    XCTAssertEqual([path count], 3U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:0]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:1]);
    XCTAssertEqualObjects([path objectAtIndex:2], [NSNumber numberWithInt:3]);
    XCTAssertEqual([dij getCostToTarget], 1.5);
}

- (void)testComplicatedDijkstra {
    SparseGraph *graph = [OGraphTests complicatedCostedDigraph];
    GraphSearchDijkstra *dij = [[GraphSearchDijkstra alloc] initWithGraph:graph sourceNodeIndex:4 targetNodeIndex:2];
    NSArray *path = [dij getPathToTarget];
    // cheapest path from 4=>2 is 4=>1=>2, with a total cost of 5.0
    XCTAssertEqual([path count], 3U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:4]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:1]);
    XCTAssertEqualObjects([path objectAtIndex:2], [NSNumber numberWithInt:2]);
    XCTAssertEqual([dij getCostToTarget], 5.0);
}

+ (SparseGraph *)threeByThreeNavGraph {
    // make a small 3x3 grid of nodes
    // 0 - 1 - 2
    // | X | X |
    // 3 - 4 - 5
    // | X | X |
    // 6 - 7 - 8
    SparseGraph *graph = [[SparseGraph alloc] initWithIsDigraph:NO];
    NSUInteger idx = 0;
    for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
            // give then positions, assuming 50px grid tile size
            CGPoint pos = CGPointMake(col * 50.0, row * 50.0);
            NavGraphNode *n = [[NavGraphNode alloc] initWithIndex:idx position:pos];
            [graph addNode:n];
            idx++;
        }
    }
    [graph addEdgeFrom:0 to:1];
    [graph addEdgeFrom:0 to:3];
    [graph addEdgeFrom:0 to:4];
    [graph addEdgeFrom:1 to:2];
    [graph addEdgeFrom:1 to:3];
    [graph addEdgeFrom:1 to:4];
    [graph addEdgeFrom:1 to:4];
    [graph addEdgeFrom:2 to:4];
    [graph addEdgeFrom:2 to:5];
    [graph addEdgeFrom:3 to:4];
    [graph addEdgeFrom:3 to:6];
    [graph addEdgeFrom:3 to:7];
    [graph addEdgeFrom:4 to:6];
    [graph addEdgeFrom:4 to:7];
    [graph addEdgeFrom:4 to:8];
    [graph addEdgeFrom:5 to:7];
    [graph addEdgeFrom:5 to:8];
    [graph addEdgeFrom:6 to:7];
    [graph addEdgeFrom:7 to:8];
    return graph;
}

// Convenience method to test AStar with a given    heuristic
- (void)aStarWithHeuristic:(id<Heuristic>)heuristic {
    SparseGraph *graph = [OGraphTests threeByThreeNavGraph];
    // find a path from our bottom center node (7) to our top center (1)
    GraphSearchAStar *aStar = [[GraphSearchAStar alloc] initWithGraph:graph 
                                                      sourceNodeIndex:7 
                                                      targetNodeIndex:1 
                                                            heuristic:heuristic];
    NSArray *path = [aStar getPathToTarget];
    // best path will be straight up the middle column: 7=>4=>1
    XCTAssertEqual([path count], 3U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:7]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:4]);
    XCTAssertEqualObjects([path objectAtIndex:2], [NSNumber numberWithInt:1]);
    
    // do another search
    // find a path from our lower-left (6) to our upper right (2)
    aStar = [[GraphSearchAStar alloc] initWithGraph:graph 
                                    sourceNodeIndex:6 
                                    targetNodeIndex:2 
                                          heuristic:heuristic];
    path = [aStar getPathToTarget];
    // best path will be the diagonal: 6=>4=>2
    XCTAssertEqual([path count], 3U);
    XCTAssertEqualObjects([path objectAtIndex:0], [NSNumber numberWithInt:6]);
    XCTAssertEqualObjects([path objectAtIndex:1], [NSNumber numberWithInt:4]);
    XCTAssertEqualObjects([path objectAtIndex:2], [NSNumber numberWithInt:2]);
    
}

- (void)testAStarWithEuclid {
    HeuristicEuclid *heuristic = [[HeuristicEuclid alloc] init];
    [self aStarWithHeuristic:heuristic];
}

- (void)testAStarWithManhattan {
    HeuristicManhattan *heuristic = [[HeuristicManhattan alloc] init];
    [self aStarWithHeuristic:heuristic];
}

- (void)testArchiveAndNewFromFile {
    // our test target uses a different bundle than [NSBundle mainBundle]
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *archivePath = [[bundle bundlePath] stringByAppendingPathComponent:@"sgArchive.data"];

    // archive a test graph to a file
    SparseGraph *archive = [OGraphTests minimalDigraph];
    [archive archiveToFile:archivePath];
    
    // then load it
    SparseGraph *graph = [SparseGraph newFromFile:archivePath];
    
    // make sure it's the graph we expect
    XCTAssertNotNil(graph);    
    XCTAssertEqual(graph.numNodes, 2U);
    XCTAssertEqual(graph.numActiveNodes, 2U);
    XCTAssertEqual(graph.numEdges, 1U);
    XCTAssertTrue([graph isNodePresentWithIndex:0]);
    XCTAssertTrue([graph isNodePresentWithIndex:1]);
    XCTAssertFalse([graph isNodePresentWithIndex:2]);
    XCTAssertTrue([graph isEdgePresentWithFrom:0 to:1]);    
    XCTAssertFalse([graph isEdgePresentWithFrom:1 to:0]);    
    
 
    // remove test file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:archivePath error:NULL];
}

- (void)testArchiveAndNewFromFileWithNavGraphNode {
    // our test target uses a different bundle than [NSBundle mainBundle]
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *archivePath = [[bundle bundlePath] stringByAppendingPathComponent:@"sgArchive.data"];
    
    // archive a test graph to a file
    SparseGraph *archive = [OGraphTests minimalNavGraph];
    [archive archiveToFile:archivePath];
    
    // then load it
    SparseGraph *graph = [SparseGraph newFromFile:archivePath];
    
    // make sure it's the graph we expect
    XCTAssertNotNil(graph);    
    XCTAssertEqual(graph.numNodes, 2U);
    XCTAssertEqual(graph.numActiveNodes, 2U);
    // undirected graph, so edges to and from
    XCTAssertEqual(graph.numEdges, 2U);
    XCTAssertTrue([graph isNodePresentWithIndex:0]);
    XCTAssertTrue([graph isNodePresentWithIndex:1]);
    XCTAssertFalse([graph isNodePresentWithIndex:2]);
    XCTAssertTrue([graph isEdgePresentWithFrom:0 to:1]);    
    XCTAssertTrue([graph isEdgePresentWithFrom:1 to:0]);    
    

    // remove test file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:archivePath error:NULL];
}

- (void)testMediumMapGraph {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    SparseGraph *graph = [SparseGraph newFromFile:[bundle pathForResource:@"mediumMapGraph" ofType:@"data"]];
    HeuristicManhattan *heuristic = [[HeuristicManhattan alloc] init];

    GraphSearchAStar *aStar = [[GraphSearchAStar alloc] initWithGraph:graph 
                                                      sourceNodeIndex:0 
                                                      targetNodeIndex:870 
                                                            heuristic:heuristic];
    NSArray *path = [aStar getPathToTarget];
    XCTAssertNotNil(path);    
}

@end
