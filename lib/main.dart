import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:tree_demo/painter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TreeNodeData(),
      child: const MyApp(),
    ),
  );
}

class TreeNode {
  int id;
  int? parentId;
  List<int> childrenIds;
  Color color;
  double x;
  double y;

  TreeNode({
    required this.id,
    this.parentId,
    this.childrenIds = const [],
    required this.color,
    this.x = 0.0,
    this.y = 0.0,
  });
}

class TreeNodeData extends ChangeNotifier {
  final Map<int, TreeNode> _nodes = {};
  int _nextNodeId = 1;
  int? _selectedNodeId;
  double spaceX = 100.0;
  double spaceY = 100.0;
  int maxDepth = 0;

  TreeNodeData() {
    // Add the root node
    final rootNode = TreeNode(id: _nextNodeId++, color: Colors.blue);
    _nodes[rootNode.id] = rootNode;

    // Add startNode
    final startNode = TreeNode(
      id: _nextNodeId++,
      parentId: rootNode.id,
      color: Colors.green,
    );
    _nodes[startNode.id] = startNode;
    rootNode.childrenIds = [...rootNode.childrenIds, startNode.id];

    // Add goalNode
    final goalNode = TreeNode(
      id: _nextNodeId++,
      parentId: rootNode.id,
      color: Colors.red,
    );
    _nodes[goalNode.id] = goalNode;
    rootNode.childrenIds = [...rootNode.childrenIds, goalNode.id];

    recalculatePositions();
  }

  Map<int, TreeNode> get nodes => _nodes;
  int? get selectedNodeId => _selectedNodeId;

  void addNode({int? parentId}) {
    final newNode = TreeNode(
      id: _nextNodeId++,
      parentId: parentId,
      color: _getColorForDepth(getDepth(parentId)),
    );
    _nodes[newNode.id] = newNode;

    if (parentId != null) {
      _nodes[parentId]!.childrenIds = [
        ..._nodes[parentId]!.childrenIds,
        newNode.id,
      ];
    }
    recalculatePositions();
    notifyListeners();
  }

  void removeNode(int nodeId) {
    final nodeToRemove = _nodes[nodeId];
    if (nodeToRemove == null) return;

    final parentId = nodeToRemove.parentId;
    if (parentId != null) {
      _nodes[parentId]!.childrenIds.remove(nodeId);
    }
    if (parentId == null) {
      return;
    }

    // Remove children recursively
    final childrenToRemove = [...nodeToRemove.childrenIds];
    for (final childId in childrenToRemove) {
      removeNode(childId);
    }

    _nodes.remove(nodeId);
    if (_selectedNodeId == nodeId) {
      _selectedNodeId = null;
    }
    recalculatePositions();
    notifyListeners();
  }

  void selectNode(int nodeId) {
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  Color _getColorForDepth(int depth) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.lime,
      Colors.indigo,
    ];
    return colors[depth % colors.length];
  }

  int getDepth(int? nodeId) {
    int depth = 0;
    int? currentId = nodeId;
    while (currentId != null) {
      final node = _nodes[currentId];
      if (node == null) break;
      currentId = node.parentId;
      depth++;
    }
    return depth - 1; // Subtract 1 to start depth at 0 for the root node
  }

  void recalculatePositions() {
    if (_nodes.isEmpty) return;

    // 1. Calculate depths
    _calculateMaxDepth();

    // 2. Initial placement (DFS)
    final rootNodes =
        _nodes.values.where((node) => node.parentId == null).toList();
    double currentX = 0.0;
    for (final rootNode in rootNodes) {
      _positionNodesDFS(rootNode.id, 0, currentX);
      currentX = _getMaxX(rootNode.id) + spaceX * 5;
    }

    // 3. Adjust parent positions (bottom-up)
    for (int i = maxDepth; i >= 0; i--) {
      for (final node in _nodes.values.where(
        (node) => getDepth(node.id) == i,
      )) {
        if (node.childrenIds.isNotEmpty) {
          double leftMostChildX = _nodes[node.childrenIds.first]!.x;
          double rightMostChildX = _nodes[node.childrenIds.last]!.x;
          node.x = (leftMostChildX + rightMostChildX) / 2;
        }
      }
    }
    notifyListeners();
  }

  double _positionNodesDFS(int nodeId, int depth, double currentX) {
    final node = _nodes[nodeId]!;
    node.y = depth * spaceY;
    node.color = _getColorForDepth(depth);

    if (node.childrenIds.isEmpty) {
      node.x = currentX;
      return currentX + spaceX;
    } else {
      double nextX = currentX;
      for (final childId in node.childrenIds) {
        nextX = _positionNodesDFS(childId, depth + 1, nextX);
      }
      node.x = currentX; // Temporary, will be adjusted later
      return nextX;
    }
  }

  double _getMaxX(int nodeId) {
    final node = _nodes[nodeId]!;
    double maxX = node.x;
    for (final childId in node.childrenIds) {
      maxX = math.max(maxX, _getMaxX(childId));
    }
    return maxX;
  }

  void _calculateMaxDepth() {
    maxDepth = 0;
    for (final node in _nodes.values) {
      maxDepth = math.max(maxDepth, getDepth(node.id));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tree View',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TreeViewPage(),
    );
  }
}

class TreeViewPage extends StatelessWidget {
  const TreeViewPage({Key? key}) : super(key: key);

  TreeNode? findLeftAncle(TreeNode node, Map<int, TreeNode> nodes) {
    TreeNode? currentParent = nodes[node.parentId];

    while (currentParent != null) {
      final grandParent = nodes[currentParent.parentId];
      if (grandParent == null) break;

      final ancles = grandParent.childrenIds;
      final ancleIndex = ancles.indexOf(currentParent.id);

      // 左の兄弟ノードが見つかった場合
      if (ancleIndex > 0) {
        final leftAncleId = ancles[ancleIndex - 1];
        return nodes[leftAncleId];
      }

      // 次の親を辿る
      currentParent = grandParent;
    }

    // 左の兄弟ノードが見つからなかった場合
    return null;
  }

  TreeNode? findRightAunt(TreeNode node, Map<int, TreeNode> nodes) {
    TreeNode? currentParent = nodes[node.parentId];

    while (currentParent != null) {
      final grandParent = nodes[currentParent.parentId];
      if (grandParent == null) break;

      final aunts = grandParent.childrenIds;
      final auntIndex = aunts.indexOf(currentParent.id);

      // 右の兄弟ノードが見つかった場合
      if (auntIndex >= 0 && auntIndex < aunts.length - 1) {
        final rightAuntId = aunts[auntIndex + 1];
        return nodes[rightAuntId];
      }

      // 次の親を辿る
      currentParent = grandParent;
    }

    // 右の兄弟ノードが見つからなかった場合
    return null;
  }

  TreeNode? findRightMostDescendant(TreeNode node, Map<int, TreeNode> nodes) {
    TreeNode? currentNode = node;

    while (currentNode != null && currentNode.childrenIds.isNotEmpty) {
      final rightMostChildId = currentNode.childrenIds.last;
      currentNode = nodes[rightMostChildId];
    }

    return currentNode;
  }

  TreeNode? findLeftMostDescendant(TreeNode node, Map<int, TreeNode> nodes) {
    TreeNode? currentNode = node;

    while (currentNode != null && currentNode.childrenIds.isNotEmpty) {
      final leftMostChildId = currentNode.childrenIds.first;
      currentNode = nodes[leftMostChildId];
    }

    return currentNode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tree View')),
      body: Consumer<TreeNodeData>(
        builder: (context, treeNodeData, child) {
          final nodes = treeNodeData.nodes;
          final rootNodes =
              nodes.values.where((node) => node.parentId == null).toList();
          double maxX = 0;
          double maxY = 0;
          for (final node in nodes.values) {
            maxX = math.max(maxX, node.x);
            maxY = math.max(maxY, node.y);
          }
          maxX += treeNodeData.spaceX * 5;
          maxY += treeNodeData.spaceY * 2;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SizedBox(
                  width: maxX,
                  height: maxY,
                  child: Stack(
                    children: [
                      // Draw connections
                      ...nodes.values.map((node) {
                        if (node.parentId == null) return const SizedBox.shrink();
                        final parent = nodes[node.parentId];
                        if (parent == null) return const SizedBox.shrink();
                        // Get the left sibling node
                        final siblings = parent.childrenIds;
                        final nodeIndex = siblings.indexOf(node.id);
                        if (nodeIndex <= 0)
                          return const SizedBox.shrink(); // No left sibling
                
                        final leftSiblingId = siblings[nodeIndex - 1];
                        final leftSibling = nodes[leftSiblingId];
                        if (leftSibling == null) return const SizedBox.shrink();
                        // Draw connection to left sibling
                        return CustomPaint(
                          painter: ConnectionPainterSibling(
                            start: Offset(leftSibling.x + 25, leftSibling.y + 25),
                            end: Offset(node.x + 25, node.y + 25),
                            color: Colors.grey,
                          ),
                        );
                      }).toList(),
                      // Draw Ancle connections
                      ...nodes.values.map((node) {
                        if (node.parentId == null) return const SizedBox.shrink();
                        final parent = nodes[node.parentId];
                        if (parent == null) return const SizedBox.shrink();
                        final leftAncle = findLeftAncle(node, nodes);
                        if (leftAncle == null) return const SizedBox.shrink();
                        final siblings = parent.childrenIds;
                        final nodeIndex = siblings.indexOf(node.id);
                        if (nodeIndex > 0) return const SizedBox.shrink();
                        final leftChild = findLeftMostDescendant(node, nodes);
                        return CustomPaint(
                          painter: ConnectionPainterAncle(
                            start: Offset(leftAncle.x + 25, leftAncle.y + 25),
                            end: Offset(node.x + 25, node.y + 25),
                            curveEnd:
                                leftChild != null
                                    ? Offset(leftChild.x + 25, leftChild.y + 25)
                                    : Offset(node.x + 25, node.y + 25),
                            color: Colors.grey,
                          ),
                        );
                      }).toList(),
                      // Draw aunt connections
                      ...nodes.values.map((node) {
                        if (node.parentId == null) return const SizedBox.shrink();
                        final parent = nodes[node.parentId];
                        if (parent == null) return const SizedBox.shrink();
                        final rightAunt = findRightAunt(node, nodes);
                        if (rightAunt == null) return const SizedBox.shrink();
                        final siblings = parent.childrenIds;
                        final nodeIndex = siblings.indexOf(node.id);
                        if (nodeIndex < siblings.length - 1)
                          return const SizedBox.shrink();
                        final rightChild = findRightMostDescendant(node, nodes);
                        return CustomPaint(
                          painter: ConnectionPainterAunt(
                            start: Offset(rightAunt.x + 25, rightAunt.y + 25),
                            end: Offset(node.x + 25, node.y + 25),
                            curveStart:
                                rightChild != null
                                    ? Offset(rightChild.x + 25, rightChild.y + 25)
                                    : Offset(node.x + 25, node.y + 25),
                            color: Colors.grey,
                          ),
                        );
                      }).toList(),
                      // Draw nodes
                      ...nodes.values.map((node) {
                        final isSelected = treeNodeData.selectedNodeId == node.id;
                        final rootNode = nodes.values.firstWhere(
                          (node) => node.parentId == null,
                        );
                        final startNode =
                            rootNode.childrenIds.isNotEmpty
                                ? nodes[rootNode.childrenIds.first]
                                : null;
                        final goalNode =
                            rootNode.childrenIds.isNotEmpty
                                ? nodes[rootNode.childrenIds.last]
                                : null;
                        // 特別扱い: rootNode
                        if (node.id == rootNode.id) {
                          return Positioned(
                            left: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                treeNodeData.selectNode(node.id);
                              },
                              child: Container(
                                width: 200,
                                height: 70,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.yellow,
                                          width: 3,
                                        )
                                        : null,
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ), // 角丸の正方形
                                ),
                                child: const Center(
                                  child: Text(
                                    '第一層目を増やしたい時はここを選択',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        // 特別扱い: startNode
                        if (node == startNode) {
                          return Positioned(
                            left: node.x,
                            top: node.y,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10), // 角丸の正方形
                              ),
                              child: const Center(
                                child: Text(
                                  'Start',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }
                
                        // 特別扱い: goalNode
                        if (node == goalNode) {
                          return Positioned(
                            left: node.x,
                            top: node.y,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10), // 角丸の正方形
                              ),
                              child: const Center(
                                child: Text(
                                  'Goal',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }
                
                        // 通常ノード
                        return Positioned(
                          left: node.x,
                          top: node.y,
                          child: GestureDetector(
                            onTap: () {
                              if (node != startNode && node != goalNode) {
                                treeNodeData.selectNode(node.id);
                              }
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: node.color,
                                shape: BoxShape.circle,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.yellow,
                                          width: 3,
                                        )
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  node.id.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: () {
              final treeNodeData = Provider.of<TreeNodeData>(
                context,
                listen: false,
              );
              if (treeNodeData.selectedNodeId != null) {
                treeNodeData.addNode(parentId: treeNodeData.selectedNodeId);
              }
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "remove",
            onPressed: () {
              final treeNodeData = Provider.of<TreeNodeData>(
                context,
                listen: false,
              );
              if (treeNodeData.selectedNodeId != null &&
                  treeNodeData.nodes.length > 1) {
                // Prevent deleting the root node
                treeNodeData.removeNode(treeNodeData.selectedNodeId!);
              }
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
