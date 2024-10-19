import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late List<T> _items = widget.items.toList();

  /// The index of the item being dragged.
  int? _draggingIndex;

  /// The current position of the dragged item in local container coordinates.
  Offset _dragPosition = Offset.zero;

  /// Overlay entry for displaying the dragged item.
  OverlayEntry? _dragOverlay;

  /// Global key for accessing the container’s position.
  final GlobalKey _containerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_items.length, (index) {
          return _buildDraggableItem(index);
        }),
      ),
    );
  }

  Widget _buildDraggableItem(int index) {
    final item = _items[index];

    return GestureDetector(
      onPanStart: (details) {
        _startDrag(index, details.globalPosition);
      },
      onPanUpdate: (details) {
        setState(() {
          _updateDragPosition(details.globalPosition);
          _updateOverlayPosition();
          int newIndex = _getDropTargetIndex();
          if (newIndex != _draggingIndex &&
              newIndex >= 0 &&
              newIndex < _items.length) {
            final movedItem = _items.removeAt(_draggingIndex!);
            _items.insert(newIndex, movedItem);
            _draggingIndex = newIndex; // Update the dragging index
          }
        });
      },
      onPanEnd: (details) {
        _endDrag();
      },
      child: Opacity(
        opacity: _draggingIndex == index ? 0.0 : 1.0,
        child: Transform.scale(
          scale: _draggingIndex == index ? 1.5 : 1.0,
          child: widget.builder(item),
        ),
      ),
    );
  }

  void _startDrag(int index, Offset globalPosition) {
    _draggingIndex = index;
    _updateDragPosition(globalPosition);
    _showDragOverlay();
  }

  void _updateDragPosition(Offset globalPosition) {
    // Convert the global position to the local position inside the container
    final RenderBox containerBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
    _dragPosition = containerBox.globalToLocal(globalPosition);
  }

  void _endDrag() {
    setState(() {
      _draggingIndex = null; // Reset dragging index
      _dragOverlay?.remove(); // Remove overlay
      _dragOverlay = null; // Clear overlay reference
    });
  }

  int _getDropTargetIndex() {
    double itemWidth = 60.0; 
    int newIndex = (_dragPosition.dx / itemWidth).floor();
    return newIndex.clamp(0, _items.length - 1);
  }

  void _showDragOverlay() {
    _dragOverlay = OverlayEntry(
      builder: (context) {
        final item = _items[_draggingIndex!];
        
        // Convert the local position back to global for positioning
        final RenderBox containerBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
        final globalDragPosition = containerBox.localToGlobal(_dragPosition);

        return Positioned(
          left: globalDragPosition.dx - 48, 
          top: globalDragPosition.dy - 48, 
          child: IgnorePointer(
            child: Transform.scale(
              scale: 1.5,
              child: widget.builder(item),
            ),
          ),
        );
      },
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_dragOverlay!);
  }

  void _updateOverlayPosition() {
    if (_dragOverlay != null) {
      _dragOverlay!.markNeedsBuild();
    }
  }
}
